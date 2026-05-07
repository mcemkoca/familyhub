import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin RepositoryErrorHandler {
  Future<T> handleRepositoryCall<T>(
    Future<T> Function() call,
    String operation,
  ) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        'Veritabani hatasi [$operation]: ${e.message}',
        code: e.code,
      );
    } on SocketException catch (_) {
      throw RepositoryException(
        'Internet baglantisi yok [$operation]',
        isOffline: true,
      );
    } on AuthException catch (e) {
      throw RepositoryException(
        'Oturum hatasi [$operation]: ${e.message}',
        isAuthError: true,
      );
    } catch (e) {
      throw RepositoryException(
        'Beklenmeyen hata [$operation]: $e',
      );
    }
  }
}

class RepositoryException implements Exception {
  final String message;
  final String? code;
  final bool isOffline;
  final bool isAuthError;

  RepositoryException(
    this.message, {
    this.code,
    this.isOffline = false,
    this.isAuthError = false,
  });

  @override
  String toString() => message;
}
