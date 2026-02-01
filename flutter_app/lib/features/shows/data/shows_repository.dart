import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Repository for Show-related API calls
class ShowsRepository {
  final ApiClient _apiClient;

  ShowsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all upcoming active shows
  Future<List<Show>> fetchShows() async {
    try {
      final response = await _apiClient.get(AppConfig.shows);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Show.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch details of a specific show
  Future<Show> fetchShowDetail(int id) async {
    try {
      final response = await _apiClient.get(AppConfig.showDetail(id));
      return Show.fromJson(response.data as Map<String, dynamic>);
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

/// AsyncNotifier for shows list state
class ShowsListNotifier extends AsyncNotifier<List<Show>> {
  @override
  Future<List<Show>> build() async {
    return await _fetchShows();
  }

  Future<List<Show>> _fetchShows() async {
    final repository = ref.read(showsRepositoryProvider);
    return await repository.fetchShows();
  }

  /// Refresh the shows list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchShows());
  }
}

/// Provider for shows list
final showsListProvider = AsyncNotifierProvider<ShowsListNotifier, List<Show>>(() {
  return ShowsListNotifier();
});

/// AsyncNotifier for single show detail
class ShowDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Show, int> {
  @override
  Future<Show> build(int id) async {
    return await _fetchShowDetail(id);
  }

  Future<Show> _fetchShowDetail(int id) async {
    final repository = ref.read(showsRepositoryProvider);
    return await repository.fetchShowDetail(id);
  }

  /// Refresh show detail
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchShowDetail(arg));
  }
}

/// Provider for single show detail by ID
final showDetailProvider = AsyncNotifierProvider.autoDispose
    .family<ShowDetailNotifier, Show, int>(() {
  return ShowDetailNotifier();
});
