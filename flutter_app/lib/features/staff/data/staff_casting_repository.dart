import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';

/// Un membre que l'équipe peut photographier, et où en est son book.
class CastingMember {
  const CastingMember({
    required this.id,
    required this.name,
    required this.photosTaken,
    required this.posesTotal,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? phone;
  final String? avatarUrl;

  /// Clichés déjà au book, et combien il en faut : le staff voit d'un coup
  /// d'œil qui reste à photographier.
  final int photosTaken;
  final int posesTotal;

  bool get isComplete => posesTotal > 0 && photosTaken >= posesTotal;

  factory CastingMember.fromJson(Map<String, dynamic> json) => CastingMember(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        photosTaken: json['photos_taken'] as int? ?? 0,
        posesTotal: json['poses_total'] as int? ?? 0,
      );
}

/// Le book casting d'un membre, vu par l'équipe.
///
/// Les téléphones des membres prennent souvent de mauvaises photos, et il y en
/// a toujours un qui s'éteint au moment de poser. Le staff photographie alors
/// la personne au studio : c'est le même book, seule la main qui tient
/// l'appareil change.
class StaffCastingRepository {
  StaffCastingRepository(this._api);

  final ApiClient _api;

  Future<List<CastingMember>> searchMembers({String query = ''}) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/staff/casting/members',
        queryParameters: query.isEmpty ? null : {'q': query},
      );

      return (response.data?['members'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CastingMember.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CastingBook> fetchBook(int memberId) async {
    try {
      final response = await _api
          .get<Map<String, dynamic>>('/api/staff/casting/members/$memberId');

      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Dépose un cliché dans sa case. Re-photographier une pose remplace ce qui
  /// s'y trouvait — l'ancien part à l'archive de l'équipe, côté serveur.
  Future<CastingBook> uploadPhoto({
    required int memberId,
    required CastingPose pose,
    required String photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'pose': pose.key,
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: '${pose.key}.jpg',
        ),
      });

      final response = await _api.post<Map<String, dynamic>>(
        '/api/staff/casting/members/$memberId/photos',
        data: form,
      );

      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final staffCastingRepositoryProvider = Provider<StaffCastingRepository>(
  (ref) => StaffCastingRepository(ref.watch(apiClientProvider)),
);

/// Les membres correspondant à la recherche ('' = les derniers inscrits).
final castingMembersProvider = FutureProvider.autoDispose
    .family<List<CastingMember>, String>((ref, query) async {
  return ref.read(staffCastingRepositoryProvider).searchMembers(query: query);
});

/// Le book d'un membre. Auto-disposé : on le relit en rouvrant l'écran, parce
/// qu'on vient justement d'y ajouter des clichés.
final staffCastingBookProvider =
    FutureProvider.autoDispose.family<CastingBook, int>((ref, memberId) async {
  return ref.read(staffCastingRepositoryProvider).fetchBook(memberId);
});
