import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';

// ---------------------------------------------------------------------------
// Helpers — build a DioException without a real Dio instance
// ---------------------------------------------------------------------------

DioException _makeDioException({
  required DioExceptionType type,
  int? statusCode,
  Map<String, dynamic>? responseData,
  String? message,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode != null
        ? Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: responseData,
          )
        : null,
    message: message,
  );
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // ApiException.fromDioError — message parsing
  // ─────────────────────────────────────────────────────────────────────────

  group('ApiException.fromDioError — message', () {
    test('connection timeout produces a timeout message', () {
      final e = _makeDioException(type: DioExceptionType.connectionTimeout);
      final ex = ApiException.fromDioError(e);
      expect(ex.message, contains('expiré'));
      expect(ex.statusCode, isNull);
    });

    test('send timeout produces a timeout message', () {
      final e = _makeDioException(type: DioExceptionType.sendTimeout);
      final ex = ApiException.fromDioError(e);
      expect(ex.message, contains('expiré'));
    });

    test('receive timeout produces a timeout message', () {
      final e = _makeDioException(type: DioExceptionType.receiveTimeout);
      final ex = ApiException.fromDioError(e);
      expect(ex.message, contains('expiré'));
    });

    test('connection error produces a connectivity message', () {
      final e = _makeDioException(type: DioExceptionType.connectionError);
      final ex = ApiException.fromDioError(e);
      expect(ex.message, contains('connecter'));
    });

    test('bad response uses message from response body', () {
      final e = _makeDioException(
        type: DioExceptionType.badResponse,
        statusCode: 422,
        responseData: {'message': 'Validation failed', 'errors': {}},
      );
      final ex = ApiException.fromDioError(e);
      expect(ex.message, 'Validation failed');
      expect(ex.statusCode, 422);
    });

    test('bad response falls back to default when no message key', () {
      final e = _makeDioException(
        type: DioExceptionType.badResponse,
        statusCode: 500,
        responseData: {'error': 'Internal Server Error'},
      );
      final ex = ApiException.fromDioError(e);
      expect(ex.message, isNotEmpty);
      expect(ex.statusCode, 500);
    });

    test('unknown type uses error.message', () {
      final e = _makeDioException(
        type: DioExceptionType.unknown,
        message: 'Something went wrong',
      );
      final ex = ApiException.fromDioError(e);
      expect(ex.message, 'Something went wrong');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ApiException — status code helpers
  // ─────────────────────────────────────────────────────────────────────────

  group('ApiException — status code helpers', () {
    test('isUnauthenticated true for 401', () {
      final ex = ApiException(message: 'Unauthorized', statusCode: 401);
      expect(ex.isUnauthenticated, isTrue);
      expect(ex.isForbidden, isFalse);
    });

    test('isForbidden true for 403', () {
      final ex = ApiException(message: 'Forbidden', statusCode: 403);
      expect(ex.isForbidden, isTrue);
      expect(ex.isUnauthenticated, isFalse);
    });

    test('isNotFound true for 404', () {
      final ex = ApiException(message: 'Not Found', statusCode: 404);
      expect(ex.isNotFound, isTrue);
    });

    test('isValidationError true for 422', () {
      final ex = ApiException(message: 'Validation', statusCode: 422);
      expect(ex.isValidationError, isTrue);
    });

    test('isServerError true for 500', () {
      final ex = ApiException(message: 'Server Error', statusCode: 500);
      expect(ex.isServerError, isTrue);
    });

    test('isServerError true for 503', () {
      final ex = ApiException(message: 'Service Unavailable', statusCode: 503);
      expect(ex.isServerError, isTrue);
    });

    test('isServerError false for 422', () {
      final ex = ApiException(message: 'Validation', statusCode: 422);
      expect(ex.isServerError, isFalse);
    });

    test('all helpers false when statusCode is null', () {
      final ex = ApiException(message: 'Network error');
      expect(ex.isUnauthenticated, isFalse);
      expect(ex.isForbidden, isFalse);
      expect(ex.isNotFound, isFalse);
      expect(ex.isValidationError, isFalse);
      expect(ex.isServerError, isFalse);
    });

    test('toString returns message', () {
      final ex = ApiException(message: 'Test message', statusCode: 400);
      expect(ex.toString(), 'Test message');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ApiException — errors field
  // ─────────────────────────────────────────────────────────────────────────

  group('ApiException.fromDioError — validation errors field', () {
    test('errors field populated from response', () {
      final e = _makeDioException(
        type: DioExceptionType.badResponse,
        statusCode: 422,
        responseData: {
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['The email has already been taken.'],
            'seats': ['Must be between 1 and 4.'],
          },
        },
      );
      final ex = ApiException.fromDioError(e);
      expect(ex.errors, isNotNull);
      expect(ex.errors!['email'], isA<List>());
    });

    test('errors field is null when response has no errors key', () {
      final e = _makeDioException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        responseData: {'message': 'Bad request'},
      );
      final ex = ApiException.fromDioError(e);
      expect(ex.errors, isNull);
    });
  });
}
