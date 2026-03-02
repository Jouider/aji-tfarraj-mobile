import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/profile/domain/city.dart';

class ProfileRepository {
  final ApiClient _client;

  ProfileRepository(this._client);

  /// Update profile fields (PATCH /api/me/profile)
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? cityName,
    String? district,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/me/profile',
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (cityName != null) 'city_name': cityName,
          if (district != null) 'district': district,
        },
      );
      final data = response.data!;
      return User.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload avatar (POST /api/me/avatar) — multipart
  Future<User> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        // Backend sets live_photo_captured_at only when this field is present.
        // Without it the flag stays null and profile_complete remains false.
        'live_photo_captured_at': DateTime.now().toUtc().toIso8601String(),
      });
      final response = await _client.post<Map<String, dynamic>>(
        '/api/me/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data!;
      return User.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete avatar (DELETE /api/me/avatar)
  Future<User> deleteAvatar() async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        '/api/me/avatar',
      );
      final data = response.data!;
      return User.fromJson(data['data'] ?? data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch cities with districts (GET /api/cities)
  /// Backend may return a top-level array OR a {data:[...]} wrapper
  Future<List<City>> getCities() async {
    try {
      final response = await _client.get<dynamic>('/api/cities');
      final body = response.data;
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = (body['data'] ?? body['cities'] ?? []) as List<dynamic>;
      } else {
        list = [];
      }
      return list.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRepository(client);
});

/// Cached cities — not autoDispose so it lives for the session
final citiesProvider = FutureProvider<List<City>>((ref) {
  return ref.read(profileRepositoryProvider).getCities();
});
