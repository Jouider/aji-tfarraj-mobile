import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';

/// La roue de la chance — `GET /api/me/wheel`, `POST /api/me/wheel/spin`.
class WheelRepository {
  WheelRepository(this._api);

  final ApiClient _api;

  Future<WheelStatus> fetch() async {
    try {
      final response = await _api.get<dynamic>('/api/me/wheel');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          message: 'Format de réponse inattendu',
          statusCode: response.statusCode,
        );
      }
      return WheelStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Un tour. Refusé avec le code `CLOSED` ou `NO_SPINS_LEFT`.
  Future<SpinResult> spin() async {
    try {
      final response = await _api.post<dynamic>('/api/me/wheel/spin');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          message: 'Format de réponse inattendu',
          statusCode: response.statusCode,
        );
      }
      return SpinResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final wheelRepositoryProvider = Provider<WheelRepository>(
  (ref) => WheelRepository(ref.watch(apiClientProvider)),
);

/// L'état de la roue, partagé par l'écran et ses cartes d'entrée.
final wheelProvider =
    AsyncNotifierProvider.autoDispose<WheelNotifier, WheelStatus>(
        WheelNotifier.new);

class WheelNotifier extends AutoDisposeAsyncNotifier<WheelStatus> {
  @override
  Future<WheelStatus> build() => ref.watch(wheelRepositoryProvider).fetch();

  /// Tire un tour sur le serveur, sans toucher à l'état : l'écran ne montre
  /// les nouveaux essais et le nouveau solde qu'une fois la roue arrêtée,
  /// avec [settle].
  Future<SpinResult> spin() => ref.read(wheelRepositoryProvider).spin();

  void settle(SpinResult result) {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.after(result));
    // Le reste (le gros lot encore en jeu ?) se relit en silence, sans
    // repasser par le chargement.
    unawaited(_refreshQuietly());
  }

  Future<void> _refreshQuietly() async {
    try {
      final fresh = await ref.read(wheelRepositoryProvider).fetch();
      state = AsyncData(fresh);
    } catch (_) {
      // L'état déjà affiché reste juste ; la prochaine ouverture relira.
    }
  }
}
