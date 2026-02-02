import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Paginated response for shows
class PaginatedShowsResponse {
  final List<Show> shows;
  final int currentPage;
  final int? lastPage;
  final bool hasMore;

  PaginatedShowsResponse({
    required this.shows,
    required this.currentPage,
    this.lastPage,
    required this.hasMore,
  });
}

/// Repository for Show-related API calls
class ShowsRepository {
  final ApiClient _apiClient;

  ShowsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch shows with optional pagination support
  Future<PaginatedShowsResponse> fetchShowsPaginated({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        AppConfig.shows,
        queryParameters: {'page': page},
      );

      final data = response.data;

      // Handle paginated response: { data: [...], meta: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        final List<dynamic> showsData = data['data'] as List<dynamic>;
        final shows = showsData
            .map((json) => Show.fromJson(json as Map<String, dynamic>))
            .toList();

        int currentPage = page;
        int? lastPage;
        bool hasMore = false;

        if (data.containsKey('meta') && data['meta'] is Map) {
          final meta = data['meta'] as Map<String, dynamic>;
          currentPage = meta['current_page'] as int? ?? page;
          lastPage = meta['last_page'] as int?;
          hasMore = lastPage != null && currentPage < lastPage;
        } else if (data.containsKey('links') && data['links'] is Map) {
          final links = data['links'] as Map<String, dynamic>;
          hasMore = links['next'] != null;
        }

        return PaginatedShowsResponse(
          shows: shows,
          currentPage: currentPage,
          lastPage: lastPage,
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
          hasMore: false,
        );
      }

      return PaginatedShowsResponse(
        shows: [],
        currentPage: 1,
        lastPage: 1,
        hasMore: false,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch all shows (backward compatibility)
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
    }
  }
}

/// Provider for ShowsRepository
final showsRepositoryProvider = Provider<ShowsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShowsRepository(apiClient: apiClient);
});

/// State for paginated shows list
class ShowsListState {
  final List<Show> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const ShowsListState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ShowsListState copyWith({
    List<Show>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return ShowsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  List<String> get uniqueCities {
    final cities = items.map((s) => s.city).toSet().toList();
    cities.sort();
    return cities;
  }

  List<String> get uniqueChannels {
    final channels = items
        .where((s) => s.channel != null && s.channel!.isNotEmpty)
        .map((s) => s.channel!)
        .toSet()
        .toList();
    channels.sort();
    return channels;
  }
}

/// Pagination-ready Notifier for shows list
class ShowsListNotifier extends Notifier<ShowsListState> {
  @override
  ShowsListState build() {
    Future.microtask(() => loadInitial());
    return const ShowsListState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = const ShowsListState(isLoading: true);
    try {
      final repository = ref.read(showsRepositoryProvider);
      final response = await repository.fetchShowsPaginated(page: 1);
      state = ShowsListState(
        items: response.shows,
        page: response.currentPage,
        hasMore: response.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = ShowsListState(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repository = ref.read(showsRepositoryProvider);
      final response = await repository.fetchShowsPaginated(page: state.page + 1);
      state = state.copyWith(
        items: [...state.items, ...response.shows],
        page: response.currentPage,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

/// Provider for paginated shows list
final showsListProvider = NotifierProvider<ShowsListNotifier, ShowsListState>(() {
  return ShowsListNotifier();
});

/// Filter state for shows
class ShowsFilterState {
  final String? selectedCity;
  final String? selectedChannel;
  final String? selectedCategory; // TODO: Implement when Show model has category

  const ShowsFilterState({this.selectedCity, this.selectedChannel, this.selectedCategory});

  ShowsFilterState copyWith({
    String? selectedCity,
    String? selectedChannel,
    String? selectedCategory,
    bool clearCity = false,
    bool clearChannel = false,
    bool clearCategory = false,
  }) {
    return ShowsFilterState(
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      selectedChannel: clearChannel ? null : (selectedChannel ?? this.selectedChannel),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  bool get hasFilters => selectedCity != null || selectedChannel != null || selectedCategory != null;
}

/// Notifier for filter state
class ShowsFilterNotifier extends Notifier<ShowsFilterState> {
  @override
  ShowsFilterState build() => const ShowsFilterState();

  void setCity(String? city) {
    state = state.copyWith(selectedCity: city, clearCity: city == null);
  }

  void setChannel(String? channel) {
    state = state.copyWith(selectedChannel: channel, clearChannel: channel == null);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category, clearCategory: category == null);
  }

  void clearAll() {
    state = const ShowsFilterState();
  }
}

/// Provider for filter state
final showsFilterProvider = NotifierProvider<ShowsFilterNotifier, ShowsFilterState>(() {
  return ShowsFilterNotifier();
});

/// Provider for filtered shows list
final filteredShowsProvider = Provider<List<Show>>((ref) {
  final showsState = ref.watch(showsListProvider);
  final filterState = ref.watch(showsFilterProvider);
  var shows = showsState.items;

  if (filterState.selectedCity != null) {
    shows = shows.where((s) => s.city == filterState.selectedCity).toList();
  }
  if (filterState.selectedChannel != null) {
    shows = shows.where((s) => s.channel == filterState.selectedChannel).toList();
  }
  // TODO: Apply category filter when Show model has category field
  return shows;
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
