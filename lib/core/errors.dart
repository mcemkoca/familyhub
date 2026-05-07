class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

class AppDatabaseException implements Exception {
  final String message;
  AppDatabaseException(this.message);
  @override
  String toString() => message;
}

String friendlyErrorMessage(Object? error) {
  if (error == null) return 'Bir şeyler yanlış gitti, lütfen tekrar deneyin.';
  final msg = error.toString().toLowerCase();

  // Ağ hataları öncelikli
  if (msg.contains('socket') || msg.contains('connection') || msg.contains('timeout') || msg.contains('network') || msg.contains('internet')) {
    return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
  }

  // Oturum hataları
  if (msg.contains('jwt') || msg.contains('auth') || msg.contains('login') || msg.contains('giriş') || msg.contains('oturum') || msg.contains('unauthorized')) {
    return 'Oturum süreniz dolmuş olabilir. Lütfen tekrar giriş yapın.';
  }

  // RLS / recursion spesifik
  if (msg.contains('infinite recursion') || msg.contains('rls')) {
    return 'Veritabanı güvenlik ayarları nedeniyle veriye erişilemiyor. Lütfen daha sonra tekrar deneyin.';
  }

  // family_id null / aile yok / foreign key hataları
  if (msg.contains('family_id') ||
      msg.contains('aile') ||
      msg.contains('family') ||
      msg.contains('no family') ||
      msg.contains('null value in column') ||
      msg.contains('foreign key')) {
    return 'Aile bilginize ulaşılamıyor. Lütfen aile ayarlarından bir aile oluşturun veya davet kodu ile katılın.';
  }

  // PostgrestException genel (diğer özel durumlar yakalanmadıysa)
  if (msg.contains('postgrestexception')) {
    return 'Veritabanından veri alınırken bir sorun oluştu. Lütfen tekrar deneyin.';
  }

  if (msg.contains('not found') || msg.contains('bulunamadı')) {
    return 'İstenen veri bulunamadı.';
  }

  return 'Bir şeyler yanlış gitti, lütfen tekrar deneyin.';
}
