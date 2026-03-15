import 'package:dio/dio.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/features/auth/data/auth_local_source.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final AuthLocalSource _authLocal;

  AuthInterceptor(this._dio, this._authLocal);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login/refresh
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    // Pour les requêtes multipart (FormData), refresher proactivement le token
    // car FormData ne peut pas être réutilisé en cas de retry après un 401.
    if (options.data is FormData) {
      final refreshToken = await _authLocal.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            ApiConstants.refresh,
            data: {'refresh_token': refreshToken},
          );
          final newAccessToken = response.data['access_token'] as String;
          final newRefreshToken = response.data['refresh_token'] as String;
          await _authLocal.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          return handler.next(options);
        } catch (_) {
          // Si le refresh échoue, on laisse la requête partir avec le token actuel
        }
      }
    }

    final token = await _authLocal.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _authLocal.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            ApiConstants.refresh,
            data: {'refresh_token': refreshToken},
          );

          final newAccessToken = response.data['access_token'] as String;
          final newRefreshToken = response.data['refresh_token'] as String;
          await _authLocal.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // FormData (multipart) ne peut pas être réutilisé après envoi :
          // on sauvegarde le nouveau token mais on ne peut pas retry.
          // L'utilisateur devra relancer l'action manuellement.
          if (err.requestOptions.data is FormData) {
            return handler.next(err);
          }

          // Retry original request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh échoué (token expiré côté serveur) → forcer la déconnexion
          await _authLocal.clearAll();
        }
      }
    }
    handler.next(err);
  }
}
