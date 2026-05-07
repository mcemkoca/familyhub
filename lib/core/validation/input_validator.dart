/// OWASP-aligned input validation and sanitization.
class InputValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(
    r'^(\+[0-9]{10,15}|0[0-9]{10})$',
  );

  static final _nameRegex = RegExp(
    r"^[a-zA-ZğüşıöçĞÜŞİÖÇ\s'-]{2,50}$",
  );

  static final _dangerousChars = RegExp(
    '[<>\\"\\\';&+\\\\()]',
  );

  static final _passwordUpper = RegExp(r'[A-Z]');
  static final _passwordLower = RegExp(r'[a-z]');
  static final _passwordDigit = RegExp(r'[0-9]');
  static final _passwordSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // ── Validators ──

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'E-posta zorunlu';
    if (value.length > 254) return 'E-posta çok uzun';
    if (!_emailRegex.hasMatch(value)) return 'Geçerli e-posta girin';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Telefon zorunlu';
    if (!_phoneRegex.hasMatch(value)) {
      return 'Geçerli telefon girin (örn: 05321234567 veya +905321234567)';
    }
    return null;
  }

  /// Normalizes a Turkish phone number to E.164 format (+90...).
  /// Accepts: 05321234567, 5321234567, +905321234567
  static String normalizePhone(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (value.startsWith('+')) {
      return value;
    }
    if (value.startsWith('0') && digitsOnly.length == 11) {
      return '+90${digitsOnly.substring(1)}';
    }
    if (digitsOnly.length == 10) {
      return '+90$digitsOnly';
    }
    return value;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Ad zorunlu';
    if (value.length < 2) return 'En az 2 karakter';
    if (value.length > 50) return 'En fazla 50 karakter';
    if (!_nameRegex.hasMatch(value)) return 'Geçersiz karakterler';
    if (_dangerousChars.hasMatch(value)) return 'Özel karakterler kullanılamaz';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre zorunlu';
    if (value.length < 8) return 'En az 8 karakter';
    if (value.length > 128) return 'En fazla 128 karakter';
    if (!_passwordUpper.hasMatch(value)) return 'En az 1 büyük harf';
    if (!_passwordLower.hasMatch(value)) return 'En az 1 küçük harf';
    if (!_passwordDigit.hasMatch(value)) return 'En az 1 rakam';
    if (!_passwordSpecial.hasMatch(value)) return 'En az 1 özel karakter';
    return null;
  }

  static String? validateNotEmpty(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName zorunlu';
    return null;
  }

  static String? validateMaxLength(String? value, int max, {String fieldName = 'Bu alan'}) {
    if (value != null && value.length > max) {
      return '$fieldName en fazla $max karakter olabilir';
    }
    return null;
  }

  // ── Sanitization ──

  static String sanitize(String input) {
    return input
        .replaceAll(_dangerousChars, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Strip HTML-like tags to prevent XSS in display contexts.
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
