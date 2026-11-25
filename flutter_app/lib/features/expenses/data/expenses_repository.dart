import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/expenses/domain/expense.dart';

/// Les dépenses de Hamza : sa caisse, ses saisies, les photos des reçus.
class ExpensesRepository {
  ExpensesRepository(this._api);

  final ApiClient _api;

  Future<ExpensesOverview> overview() async =>
      ExpensesOverview.fromJson(await _get('${AppConfig.expenses}/overview'));

  Future<ExpenseFormOptions> form() async =>
      ExpenseFormOptions.fromJson(await _get('${AppConfig.expenses}/form'));

  Future<ExpensePage> list({String? status, int page = 1}) async =>
      ExpensePage.fromJson(await _get(AppConfig.expenses, query: {
        if (status != null) 'status': status,
        'page': page,
      }));

  /// Une nouvelle dépense, avec les photos des reçus (chemins locaux).
  Future<Expense> create(ExpenseDraft draft, List<String> photoPaths) =>
      _send(AppConfig.expenses, draft, photoPaths);

  /// Corriger une dépense en attente ou refusée ; les photos s'ajoutent.
  Future<Expense> update(int id, ExpenseDraft draft, List<String> photoPaths) =>
      _send('${AppConfig.expenses}/$id', draft, photoPaths);

  Future<void> delete(int id) =>
      _guard(() => _api.delete<dynamic>('${AppConfig.expenses}/$id'));

  Future<Expense> deletePhoto(int expenseId, int photoId) async {
    final res = await _guard(() => _api.delete<Map<String, dynamic>>(
        '${AppConfig.expenses}/$expenseId/photos/$photoId'));
    return Expense.fromJson(res.data ?? const {});
  }

  /// Le fichier d'un reçu : il passe par l'API (jeton compris), jamais par
  /// une URL publique.
  Future<Uint8List> photoBytes(String url) async {
    final res = await _guard(() => _api.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        ));
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Expense> _send(
      String path, ExpenseDraft draft, List<String> photoPaths) async {
    final form = FormData.fromMap(draft.toFields());
    for (var i = 0; i < photoPaths.length; i++) {
      final p = photoPaths[i];
      final ext = p.toLowerCase().endsWith('.pdf') ? 'pdf' : 'jpg';
      form.files.add(MapEntry(
        'photos[]',
        await MultipartFile.fromFile(p, filename: 'recu-${i + 1}.$ext'),
      ));
    }
    final res =
        await _guard(() => _api.post<Map<String, dynamic>>(path, data: form));
    final body = res.data ?? const <String, dynamic>{};
    return Expense.fromJson(body['expense'] is Map
        ? Map<String, dynamic>.from(body['expense'] as Map)
        : body);
  }

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    final res = await _guard(
        () => _api.get<Map<String, dynamic>>(path, queryParameters: query));
    return res.data ?? const {};
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(apiClientProvider));
});

final expensesOverviewProvider =
    FutureProvider.autoDispose<ExpensesOverview>((ref) {
  return ref.watch(expensesRepositoryProvider).overview();
});

final expenseFormOptionsProvider =
    FutureProvider.autoDispose<ExpenseFormOptions>((ref) {
  return ref.watch(expensesRepositoryProvider).form();
});

/// La première page d'un état (`pending` | `validated` | `refused`).
final expensesByStatusProvider =
    FutureProvider.autoDispose.family<ExpensePage, String>((ref, status) {
  return ref.watch(expensesRepositoryProvider).list(status: status);
});
