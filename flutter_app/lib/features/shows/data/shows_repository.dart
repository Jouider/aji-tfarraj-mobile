import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Default items per page
const int kDefaultPerPage = 10;

/// Maximum items per page (API limit)
const int kMaxPerPage = 50;

/// Debounce duration for search input
const Duration kSearchDebounceDuration = Duration(milliseconds: 300);

/// Query parameters for fetching shows
class ShowsQueryParams {
  final int page;
  final int perPage;
  final String? city;
  final String? channel;
  final String? search;

  const ShowsQueryParams({
    this.page = 1,
    this.perPage = kDefaultPerPage,
    this.city,
    this.channel,
    this.search,
  });

  /// Convert to query parameters map for API request
  /// Dio handles URL encoding automatically when using queryParameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage.clamp(1, kMaxPerPage),
    };

    if (city != null && city!.isNotEmpty) {
      params['city'] = city;
    }
    if (channel != null && channel!.isNotEmpty) {
      params['channel'] = channel;
    }
    if (search != null && search!.isNotEmpty) {
      params['q'] = search;
    }

    return params;
  }

  ShowsQueryParams copyWith({
    int? page,
    int? perPage,
    String? city,
    String? channel,
    String? search,
    bool clearCity = false,
    bool clearChannel = false,
    bool clearSearch = false,
  }) {
    return ShowsQueryParams(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      city: clearCity ? null : (city ?? this.city),
      channel: clearChannel ? null : (channel ?? this.channel),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  /// Check if any filters are applied
  bool get hasFilters => city != null || channel != null || (search != null && search!.isNotEmpty);

  /// Create a reset copy (page 1, keep other params)
  ShowsQueryParams resetPagination() => copyWith(page: 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowsQueryParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          perPage == other.perPage &&
          city == other.city &&
          channel == other.channel &&
          search == other.search;

  @override
  int get hashCode =>
      page.hashCode ^
      perPage.hashCode ^
      city.hashCode ^
      channel.hashCode ^
      search.hashCode;

  @override
  String toString() => 'ShowsQueryParams(page: $page, city: $city, channel: $channel, search: $search)';
}

/// Paginated response for shows
class PaginatedShowsResponse {
  final List<Show> shows;
  final int currentPage;
  final int? lastPage;
  final int? total;
  final bool hasMore;

  PaginatedShowsResponse({
    required this.shows,
    required this.currentPage,
    this.lastPage,
    this.total,
    required this.hasMore,
  });
}

/// Repository for Show-related API calls
class ShowsRepository {
  final ApiClient _apiClient;

  ShowsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch shows with server-side filtering and pagination
  /// 
  /// Supports:
  /// - `page`: Page number (default: 1)
  /// - `perPage`: Items per page (default: 10, max: 50)
  /// - `city`: Filter by city (case-insensitive exact match)
  /// - `channel`: Filter by channel (case-insensitive exact match)
  /// - `search`: Search in title and description (partial match)
  Future<PaginatedShowsResponse> fetchShowsPaginated({
    int page = 1,
    int perPage = kDefaultPerPage,
    String? city,
    String? channel,
    String? search,
  }) async {
    final params = ShowsQueryParams(
      page: page,
      perPage: perPage,
      city: city,
      channel: channel,
      search: search,
    );
    return fetchShowsWithParams(params);
  }

  /// Fetch shows using ShowsQueryParams object
  Future<PaginatedShowsResponse> fetchShowsWithParams(ShowsQueryParams params) async {
    try {
      final response = await _apiClient.get(
        AppConfig.shows,
        queryParameters: params.toQueryParameters(),
      );

      final data = response.data;

      // Handle paginated response: { data: [...], meta: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        final List<dynamic> showsData = data['data'] as List<dynamic>;
        final shows = showsData
            .map((json) => Show.fromJson(json as Map<String, dynamic>))
            .toList();

        int currentPage = params.page;
        int? lastPage;
        int? total;
        bool hasMore = false;

        // Parse pagination meta
        if (data.containsKey('last_page')) {
          // Laravel default pagination format
          currentPage = data['current_page'] as int? ?? params.page;
          lastPage = data['last_page'] as int?;
          total = data['total'] as int?;
          hasMore = lastPage != null && currentPage < lastPage;
        } else if (data.containsKey('meta') && data['meta'] is Map) {
          // Wrapped meta format
          final meta = data['meta'] as Map<String, dynamic>;
          currentPage = meta['current_page'] as int? ?? params.page;
          lastPage = meta['last_page'] as int?;
          total = meta['total'] as int?;
          hasMore = lastPage != null && currentPage < lastPage;
        } else if (data.containsKey('links') && data['links'] is Map) {
          // Links-based pagination
          final links = data['links'] as Map<String, dynamic>;
          hasMore = links['next'] != null;
        }

        return PaginatedShowsResponse(
          shows: shows,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
          hasMore: hasMore,
        );
      }

      // Handle non-paginated response: direct array
      if (data is List<dynamic>) {
        final shows = data
            .map((json) => Show.fromJson(json as Map<String, dynamic>))
            .toList();

        return PaginatedShowsResponse(
          shows: shows,
          currentPage: 1,
          lastPage: 1,
          total: shows.length,
          hasMore: false,
        );
      }

      return PaginatedShowsResponse(
        shows: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
        hasMore: false,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Fetch all shows (backward compatibility - no filters)
  Future<List<Show>> fetchShows() async {
    final response = await fetchShowsPaginated(page: 1);
    return response.shows;
  }

  /// Fetch details of a specific show
  Future<Show> fetchShowDetail(int id) async {
    try {
      final response = await _apiClient.get(AppConfig.showDetail(id));
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return Show.fromJson(data['data'] as Map<String, dynamic>);
      }
      return Show.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Provider for ShowsRepository
final showsRepositoryProvider = Provider<ShowsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShowsRepository(apiClient: apiClient);
});

/// State for paginated shows list with server-side filtering
class ShowsListState {
  final List<Show> items;
  final int page;
  final int? lastPage;
  final int? total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final ShowsQueryParams queryParams;

  const ShowsListState({
    this.items = const [],
    this.page = 0,
    this.lastPage,
    this.total,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.queryParams = const ShowsQueryParams(),
  });

  ShowsListState copyWith({
    List<Show>? items,
    int? page,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    ShowsQueryParams? queryParams,
  }) {
    return ShowsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      queryParams: queryParams ?? this.queryParams,
    );
  }

  /// Get unique cities from loaded items (for filter dropdown)
  List<String> get uniqueCities {
    final cities = items.map((s) => s.city).toSet().toList();
    cities.sort();
    return cities;
  }

  /// Get unique channels from loaded items (for filter dropdown)
  List<String> get uniqueChannels {
    final channels = items
        .where((s) => s.channel != null && s.channel!.isNotEmpty)
        .map((s) => s.channel!)
        .toSet()
        .toList();
    channels.sort();
    return channels;
  }

  /// Check if filters are currently applied
  bool get hasFilters => queryParams.hasFilters;
}

/// Pagination-ready Notifier for shows list with server-side filtering
class ShowsListNotifier extends Notifier<ShowsListState> {
  Timer? _searchDebounceTimer;

  @override
  ShowsListState build() {
    // Cancel debounce timer when notifier is disposed
    ref.onDispose(() {
      _searchDebounceTimer?.cancel();
    });
    Future.microtask(() => loadInitial());
    return const ShowsListState(isLoading: true);
  }

  /// Load initial page (resets pagination completely)
  Future<void> loadInitial({ShowsQueryParams? params}) async {
    final queryParams = (params ?? state.queryParams).resetPagination();
    
    // Reset state: clear items, page=1, hasMore=true
    state = ShowsListState(
      items: const [], // Clear existing items
      page: 1,
      hasMore: true,
      isLoading: true,
      queryParams: queryParams,
    );
    
    try {
      final repository = ref.read(showsRepositoryProvider);
      final response = await repository.fetchShowsWithParams(queryParams);
      state = ShowsListState(
        items: response.shows,
        page: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
        hasMore: response.hasMore,
        isLoading: false,
        queryParams: queryParams,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page (pagination) - uses same query params
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    
    state = state.copyWith(isLoadingMore: true);
    
    try {
      final repository = ref.read(showsRepositoryProvider);
      final nextParams = state.queryParams.copyWith(page: state.page + 1);
      final response = await repository.fetchShowsWithParams(nextParams);
      
      state = state.copyWith(
        items: [...state.items, ...response.shows],
        page: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
        hasMore: response.hasMore,
        isLoadingMore: false,
        queryParams: nextParams,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh (reload from page 1 with current filters)
  Future<void> refresh() async {
    await loadInitial(params: state.queryParams);
  }

  /// Apply filters and reload (resets pagination)
  Future<void> _applyFiltersAndReload(ShowsQueryParams newParams) async {
    // Cancel any pending search debounce
    _searchDebounceTimer?.cancel();
    await loadInitial(params: newParams);
  }

  /// Set city filter (immediate, resets pagination)
  Future<void> setCity(String? city) async {
    if (city == state.queryParams.city) return;
    final newParams = state.queryParams.copyWith(
      city: city,
      clearCity: city == null,
    );
    await _applyFiltersAndReload(newParams);
  }

  /// Set channel filter (immediate, resets pagination)
  Future<void> setChannel(String? channel) async {
    if (channel == state.queryParams.channel) return;
    final newParams = state.queryParams.copyWith(
      channel: channel,
      clearChannel: channel == null,
    );
    await _applyFiltersAndReload(newParams);
  }

  /// Set search query with debouncing (300ms delay)
  /// Prevents API spam on every keystroke
  void setSearchDebounced(String? search) {
    final trimmed = search?.trim();
    
    // Cancel any existing timer
    _searchDebounceTimer?.cancel();
    
    // If search is the same, don't do anything
    if (trimmed == state.queryParams.search) return;
    
    // Start new debounce timer
    _searchDebounceTimer = Timer(kSearchDebounceDuration, () {
      _executeSearch(trimmed);
    });
  }

  /// Set search query immediately (no debounce - use for "submit" actions)
  Future<void> setSearchImmediate(String? search) async {
    _searchDebounceTimer?.cancel();
    await _executeSearch(search?.trim());
  }

  /// Execute search (internal)
  Future<void> _executeSearch(String? search) async {
    if (search == state.queryParams.search) return;
    final newParams = state.queryParams.copyWith(
      search: search,
      clearSearch: search == null || search.isEmpty,
    );
    await _applyFiltersAndReload(newParams);
  }

  /// Clear all filters (resets pagination)
  Future<void> clearFilters() async {
    _searchDebounceTimer?.cancel();
    if (!state.hasFilters) return;
    await loadInitial(params: const ShowsQueryParams());
  }

  /// Clear only search filter
  Future<void> clearSearch() async {
    _searchDebounceTimer?.cancel();
    if (state.queryParams.search == null) return;
    await _executeSearch(null);
  }
}

/// Provider for paginated shows list
final showsListProvider = NotifierProvider<ShowsListNotifier, ShowsListState>(() {
  return ShowsListNotifier();
});

/// Filter state for shows (kept for backward compatibility, now delegates to server-side)
class ShowsFilterState {
  final String? selectedCity;
  final String? selectedChannel;
  final String? searchQuery;

  const ShowsFilterState({
    this.selectedCity,
    this.selectedChannel,
    this.searchQuery,
  });

  ShowsFilterState copyWith({
    String? selectedCity,
    String? selectedChannel,
    String? searchQuery,
    bool clearCity = false,
    bool clearChannel = false,
    bool clearSearch = false,
  }) {
    return ShowsFilterState(
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      selectedChannel: clearChannel ? null : (selectedChannel ?? this.selectedChannel),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters => selectedCity != null || selectedChannel != null || (searchQuery != null && searchQuery!.isNotEmpty);
}

/// Notifier for filter state (backward compatibility)
class ShowsFilterNotifier extends Notifier<ShowsFilterState> {
  @override
  ShowsFilterState build() => const ShowsFilterState();

  void setCity(String? city) {
    state = state.copyWith(selectedCity: city, clearCity: city == null);
    // Trigger server-side filter
    ref.read(showsListProvider.notifier).setCity(city);
  }

  void setChannel(String? channel) {
    state = state.copyWith(selectedChannel: channel, clearChannel: channel == null);
    // Trigger server-side filter
    ref.read(showsListProvider.notifier).setChannel(channel);
  }

  /// Set search with debouncing (for TextField onChange)
  void setSearchDebounced(String? search) {
    state = state.copyWith(searchQuery: search, clearSearch: search == null || search.isEmpty);
    // Trigger debounced server-side filter
    ref.read(showsListProvider.notifier).setSearchDebounced(search);
  }

  /// Set search immediately (for submit actions)
  void setSearchImmediate(String? search) {
    state = state.copyWith(searchQuery: search, clearSearch: search == null || search.isEmpty);
    // Trigger immediate server-side filter
    ref.read(showsListProvider.notifier).setSearchImmediate(search);
  }

  void clearSearch() {
    state = state.copyWith(clearSearch: true);
    ref.read(showsListProvider.notifier).clearSearch();
  }

  void clearAll() {
    state = const ShowsFilterState();
    // Trigger server-side clear
    ref.read(showsListProvider.notifier).clearFilters();
  }
}

/// Provider for filter state
final showsFilterProvider = NotifierProvider<ShowsFilterNotifier, ShowsFilterState>(() {
  return ShowsFilterNotifier();
});

/// Provider for filtered shows list (now returns server-filtered results)
final filteredShowsProvider = Provider<List<Show>>((ref) {
  final showsState = ref.watch(showsListProvider);
  // Server-side filtering is now applied, just return items
  return showsState.items;
});

/// AsyncNotifier for single show detail
class ShowDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Show, int> {
  @override
  Future<Show> build(int id) async => await _fetchShowDetail(id);

  Future<Show> _fetchShowDetail(int id) async {
    final repository = ref.read(showsRepositoryProvider);
    return await repository.fetchShowDetail(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchShowDetail(arg));
  }
}

/// Provider for single show detail by ID
final showDetailProvider = AsyncNotifierProvider.autoDispose
    .family<ShowDetailNotifier, Show, int>(() => ShowDetailNotifier());
