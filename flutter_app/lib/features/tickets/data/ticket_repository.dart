import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

/// Cache key for storing tickets list JSON
const String _cachedTicketsKey = 'cached_tickets_list_json';

/// Statuses that indicate a ticket may exist
const List<String> _ticketEligibleStatuses = ['approved', 'checked_in'];

/// Maximum number of reservation detail fetches to avoid too many requests
const int _maxDetailFetches = 10;

/// Result wrapper for tickets fetch with offline status
class TicketsFetchResult {
  final List<Ticket> tickets;
  final bool isOffline;

  const TicketsFetchResult({
    required this.tickets,
    this.isOffline = false,
  });
}

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Repository for Ticket-related API calls
class TicketRepository {
  final ApiClient _apiClient;

  TicketRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all user tickets by combining:
  /// 1. Latest ticket from GET /api/me/ticket
  /// 2. Tickets from reservations via GET /api/me/reservations
  ///    - For reservations without embedded ticket, fetch detail to get ticket
  /// Returns deduplicated, sorted list
  Future<TicketsFetchResult> fetchAllTicketsWithCache() async {
    try {
      final tickets = await _fetchAllTicketsFromNetwork();
      
      // Cache successful response
      if (tickets.isNotEmpty) {
        await _cacheTickets(tickets);
      }
      
      return TicketsFetchResult(tickets: tickets, isOffline: false);
    } on DioException catch (e) {
      // On network error, try to load from cache
      if (_isNetworkError(e)) {
        final cachedTickets = await _loadCachedTickets();
        if (cachedTickets.isNotEmpty) {
          return TicketsFetchResult(tickets: cachedTickets, isOffline: true);
        }
      }
      
      // Handle 404 as no tickets (not an error)
      if (e.response?.statusCode == 404) {
        return const TicketsFetchResult(tickets: [], isOffline: false);
      }
      
      throw ApiException.fromDioError(e);
    } catch (e) {
      // Try cache on any error
      final cachedTickets = await _loadCachedTickets();
      if (cachedTickets.isNotEmpty) {
        return TicketsFetchResult(tickets: cachedTickets, isOffline: true);
      }
      throw ApiException.from(e);
    }
  }

  /// Fetch all tickets from network by combining multiple sources
  Future<List<Ticket>> _fetchAllTicketsFromNetwork() async {
    final List<Ticket> allTickets = [];
    // Track whether any source failed specifically because the network is down.
    // If both sources yield nothing AND the network was down, we must surface a
    // network error so the caller falls back to the offline cache — otherwise
    // offline users would wrongly see an empty ticket list.
    bool sawNetworkError = false;

    // 1. Fetch latest ticket from /api/me/ticket
    try {
      final latestTicket = await _fetchLatestTicketFromNetwork();
      if (latestTicket != null) {
        allTickets.add(latestTicket);
        _debugLog('Fetched latest ticket: ${latestTicket.ticketCode}');
      }
    } on DioException catch (e) {
      if (_isNetworkError(e)) sawNetworkError = true;
      _debugLog('Failed to fetch latest ticket: $e');
      // Continue even if this fails - we'll try reservations
    } catch (e) {
      _debugLog('Failed to fetch latest ticket: $e');
    }

    // 2. Fetch tickets from reservations (with detail fetching for missing tickets)
    try {
      final reservationTickets = await _fetchTicketsFromReservations();
      allTickets.addAll(reservationTickets);
      _debugLog('Fetched ${reservationTickets.length} tickets from reservations');
    } on DioException catch (e) {
      if (_isNetworkError(e)) sawNetworkError = true;
      _debugLog('Failed to fetch tickets from reservations: $e');
      // Continue even if this fails
    } catch (e) {
      _debugLog('Failed to fetch tickets from reservations: $e');
    }

    // If we're offline and got nothing live, signal it so the caller loads the
    // cached tickets instead of returning an empty (but "online") list.
    if (allTickets.isEmpty && sawNetworkError) {
      throw DioException(
        requestOptions: RequestOptions(path: AppConfig.myTicket),
        type: DioExceptionType.connectionError,
      );
    }

    // 3. Deduplicate and sort
    final mergedTickets = _deduplicateAndSortTickets(allTickets);
    
    // Debug log final result
    _debugLog('=== TICKET MERGE RESULT ===');
    _debugLog('Total tickets after merge: ${mergedTickets.length}');
    for (final ticket in mergedTickets) {
      _debugLog('  - ID: ${ticket.id}, Code: ${ticket.ticketCode}, Show: ${ticket.show?.title ?? "N/A"}');
    }
    _debugLog('===========================');

    return mergedTickets;
  }

  /// Fetch latest ticket from /api/me/ticket endpoint
  Future<Ticket?> _fetchLatestTicketFromNetwork() async {
    final response = await _apiClient.get(AppConfig.myTicket);
    
    if (response.data == null) {
      return null;
    }
    
    final data = response.data;
    
    // Handle wrapped response: { data: {...} } or { data: [...] }
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final ticketData = data['data'];
      if (ticketData == null) {
        return null;
      }
      
      // Handle list response: { data: [...] }
      if (ticketData is List) {
        if (ticketData.isEmpty) return null;
        return Ticket.fromJson(ticketData.first as Map<String, dynamic>);
      }
      
      // Handle single object: { data: {...} }
      return Ticket.fromJson(ticketData as Map<String, dynamic>);
    }
    
    // Handle direct list response: [...]
    if (data is List) {
      if (data.isEmpty) return null;
      return Ticket.fromJson(data.first as Map<String, dynamic>);
    }
    
    // Handle direct object response
    return Ticket.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch tickets from reservations
  /// For reservations with eligible status but no embedded ticket,
  /// fetches reservation detail to extract the ticket
  Future<List<Ticket>> _fetchTicketsFromReservations() async {
    final response = await _apiClient.get(AppConfig.myReservations);
    final data = response.data;

    List<dynamic> reservationsData = [];

    // Handle paginated response: { data: [...] }
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      reservationsData = data['data'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      reservationsData = data;
    }

    final List<Ticket> tickets = [];
    final List<int> reservationIdsToFetch = [];

    // First pass: extract embedded tickets and collect IDs for detail fetching
    for (final resJson in reservationsData) {
      final reservation = Reservation.fromJson(resJson as Map<String, dynamic>);
      
      // Only process eligible statuses
      if (!_ticketEligibleStatuses.contains(reservation.status)) {
        continue;
      }

      if (reservation.ticket != null) {
        // Ticket is embedded, use it directly
        tickets.add(reservation.ticket!);
        _debugLog('Found embedded ticket for reservation ${reservation.id}');
      } else {
        // Ticket not embedded, need to fetch detail
        reservationIdsToFetch.add(reservation.id);
        _debugLog('Reservation ${reservation.id} has no embedded ticket, will fetch detail');
      }
    }

    // Second pass: fetch reservation details concurrently (bounded)
    if (reservationIdsToFetch.isNotEmpty) {
      final idsToFetch = reservationIdsToFetch.take(_maxDetailFetches).toList();
      _debugLog('Fetching details for ${idsToFetch.length} reservations...');
      
      final detailTickets = await _fetchTicketsFromReservationDetails(idsToFetch);
      tickets.addAll(detailTickets);
    }

    return tickets;
  }

  /// Fetch tickets by getting reservation details concurrently
  Future<List<Ticket>> _fetchTicketsFromReservationDetails(List<int> reservationIds) async {
    final List<Ticket> tickets = [];

    // Fetch all details concurrently
    final futures = reservationIds.map((id) => _fetchReservationDetail(id));
    final results = await Future.wait(futures, eagerError: false);

    for (final reservation in results) {
      if (reservation != null && reservation.ticket != null) {
        tickets.add(reservation.ticket!);
        _debugLog('Extracted ticket ${reservation.ticket!.ticketCode} from reservation ${reservation.id}');
      }
    }

    return tickets;
  }

  /// Fetch a single reservation detail
  Future<Reservation?> _fetchReservationDetail(int id) async {
    try {
      final response = await _apiClient.get(AppConfig.reservationDetail(id));
      final data = response.data;

      // Handle wrapped response: { data: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data') && data['data'] is Map) {
        return Reservation.fromJson(data['data'] as Map<String, dynamic>);
      }

      if (data is Map<String, dynamic>) {
        return Reservation.fromJson(data);
      }

      return null;
    } catch (e) {
      _debugLog('Failed to fetch reservation detail for $id: $e');
      return null;
    }
  }

  /// Deduplicate tickets by ticket_code and sort by generatedAt descending
  List<Ticket> _deduplicateAndSortTickets(List<Ticket> tickets) {
    // Deduplicate by ticket_code (more reliable than id for cross-source dedup)
    final Map<String, Ticket> uniqueTickets = {};
    for (final ticket in tickets) {
      final key = ticket.ticketCode;
      // Keep the one with more complete data (prefer with reservation info)
      if (!uniqueTickets.containsKey(key) ||
          (ticket.reservationInfo != null && uniqueTickets[key]?.reservationInfo == null)) {
        uniqueTickets[key] = ticket;
      }
    }

    // Sort by generatedAt descending (most recent first)
    final sortedTickets = uniqueTickets.values.toList();
    sortedTickets.sort((a, b) {
      final aDate = a.generatedAt ?? DateTime(1970);
      final bDate = b.generatedAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return sortedTickets;
  }

  /// Debug logging helper - only logs in debug mode
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[TicketRepository] $message');
    }
  }

  /// Check if the error is a network-related error
  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  /// Cache tickets list to secure storage
  Future<void> _cacheTickets(List<Ticket> tickets) async {
    try {
      final jsonList = tickets.map((t) => t.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storage.write(key: _cachedTicketsKey, value: jsonString);
    } catch (_) {
      // Silently fail on cache write errors
    }
  }

  /// Load tickets from cache
  Future<List<Ticket>> _loadCachedTickets() async {
    try {
      final jsonString = await _storage.read(key: _cachedTicketsKey);
      if (jsonString == null) {
        return [];
      }
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear cached tickets (useful on logout)
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _cachedTicketsKey);
    } catch (_) {
      // Silently fail
    }
  }

  /// Legacy method - fetch single ticket (backward compatibility)
  Future<Ticket?> fetchMyTicket() async {
    final result = await fetchAllTicketsWithCache();
    return result.tickets.isNotEmpty ? result.tickets.first : null;
  }
}

/// Provider for TicketRepository
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TicketRepository(apiClient: apiClient);
});

/// State for multiple tickets with offline indicator
class TicketsState {
  final List<Ticket> tickets;
  final bool isOffline;
  final bool isRefreshing;
  final int currentPage;

  const TicketsState({
    this.tickets = const [],
    this.isOffline = false,
    this.isRefreshing = false,
    this.currentPage = 0,
  });

  /// Check if there are no tickets
  bool get isEmpty => tickets.isEmpty;

  /// Check if there's exactly one ticket
  bool get hasSingleTicket => tickets.length == 1;

  /// Check if there are multiple tickets
  bool get hasMultipleTickets => tickets.length > 1;

  /// Get total ticket count
  int get ticketCount => tickets.length;

  /// Get current ticket based on page
  Ticket? get currentTicket => 
      tickets.isNotEmpty && currentPage < tickets.length 
          ? tickets[currentPage] 
          : null;

  TicketsState copyWith({
    List<Ticket>? tickets,
    bool? isOffline,
    bool? isRefreshing,
    int? currentPage,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// AsyncNotifier for user's tickets with offline support
class MyTicketsNotifier extends AsyncNotifier<TicketsState> {
  @override
  Future<TicketsState> build() async {
    return await _fetchMyTickets();
  }

  Future<TicketsState> _fetchMyTickets() async {
    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.fetchAllTicketsWithCache();
    return TicketsState(
      tickets: result.tickets,
      isOffline: result.isOffline,
    );
  }

  /// Refresh tickets
  Future<void> refresh() async {
    // Set refreshing state while keeping current data visible
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(isRefreshing: true));
    } else {
      state = const AsyncLoading();
    }
    
    try {
      final newState = await _fetchMyTickets();
      // Preserve current page if still valid
      final preservedPage = currentState != null && 
          currentState.currentPage < newState.tickets.length
              ? currentState.currentPage
              : 0;
      state = AsyncData(newState.copyWith(currentPage: preservedPage));
    } catch (e, stack) {
      // If we have cached data, show it with error indicator
      if (currentState != null && currentState.tickets.isNotEmpty) {
        state = AsyncData(currentState.copyWith(
          isRefreshing: false,
          isOffline: true,
        ));
      } else {
        state = AsyncError(e, stack);
      }
    }
  }

  /// Update current page (for swiper)
  void setCurrentPage(int page) {
    final currentState = state.valueOrNull;
    if (currentState != null && page >= 0 && page < currentState.tickets.length) {
      state = AsyncData(currentState.copyWith(currentPage: page));
    }
  }
}

/// Provider for user's tickets (multiple)
final myTicketsProvider = AsyncNotifierProvider<MyTicketsNotifier, TicketsState>(() {
  return MyTicketsNotifier();
});

// ============================================
// Legacy single-ticket provider (backward compatibility)
// ============================================

/// State for single ticket (backward compatibility)
class TicketState {
  final Ticket? ticket;
  final bool isOffline;
  final bool isRefreshing;

  const TicketState({
    this.ticket,
    this.isOffline = false,
    this.isRefreshing = false,
  });

  TicketState copyWith({
    Ticket? ticket,
    bool? isOffline,
    bool? isRefreshing,
    bool clearTicket = false,
  }) {
    return TicketState(
      ticket: clearTicket ? null : (ticket ?? this.ticket),
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Legacy provider that maps from multiple tickets to single ticket
final myTicketProvider = Provider<AsyncValue<TicketState>>((ref) {
  final ticketsAsync = ref.watch(myTicketsProvider);
  return ticketsAsync.whenData((ticketsState) => TicketState(
    ticket: ticketsState.tickets.isNotEmpty ? ticketsState.tickets.first : null,
    isOffline: ticketsState.isOffline,
    isRefreshing: ticketsState.isRefreshing,
  ));
});
