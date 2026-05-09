import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/core/validation/input_validator.dart';

void main() {
  group('InputValidator.validateEmail', () {
    test('returns null for valid email', () {
      expect(InputValidator.validateEmail('test@example.com'), isNull);
      expect(InputValidator.validateEmail('user.name@domain.co.uk'), isNull);
    });

    test('returns error for empty email', () {
      expect(InputValidator.validateEmail(''), 'E-posta zorunlu');
      expect(InputValidator.validateEmail(null), 'E-posta zorunlu');
    });

    test('returns error for invalid email format', () {
      expect(InputValidator.validateEmail('invalid'), 'Geçerli e-posta girin');
      expect(InputValidator.validateEmail('@example.com'), 'Geçerli e-posta girin');
      expect(InputValidator.validateEmail('user@'), 'Geçerli e-posta girin');
    });

    test('returns error for too long email', () {
      final longEmail = '${'a' * 250}@test.com';
      expect(InputValidator.validateEmail(longEmail), 'E-posta çok uzun');
    });
  });

  group('InputValidator.validatePassword', () {
    test('returns null for valid password', () {
      expect(InputValidator.validatePassword('Password123!'), isNull);
      expect(InputValidator.validatePassword('MyP@ssw0rd'), isNull);
    });

    test('returns error for empty password', () {
      expect(InputValidator.validatePassword(''), 'Şifre zorunlu');
      expect(InputValidator.validatePassword(null), 'Şifre zorunlu');
    });

    test('returns error for short password', () {
      expect(InputValidator.validatePassword('Short1!'), 'En az 8 karakter');
    });

    test('returns error for password without uppercase', () {
      expect(InputValidator.validatePassword('password123!'), 'En az 1 büyük harf');
    });

    test('returns error for password without lowercase', () {
      expect(InputValidator.validatePassword('PASSWORD123!'), 'En az 1 küçük harf');
    });

    test('returns error for password without digit', () {
      expect(InputValidator.validatePassword('Password!'), 'En az 1 rakam');
    });

    test('returns error for password without special char', () {
      expect(InputValidator.validatePassword('Password123'), 'En az 1 özel karakter');
    });

    test('returns error for too long password', () {
      expect(InputValidator.validatePassword('P@ssw0rd${'a' * 130}'), 'En fazla 128 karakter');
    });
  });

  group('InputValidator.validateName', () {
    test('returns null for valid name', () {
      expect(InputValidator.validateName('Ahmet'), isNull);
      expect(InputValidator.validateName('Mehmet Yılmaz'), isNull);
      expect(InputValidator.validateName('Ali-Can'), isNull);
    });

    test('returns error for empty name', () {
      expect(InputValidator.validateName(''), 'Ad zorunlu');
      expect(InputValidator.validateName(null), 'Ad zorunlu');
    });

    test('returns error for short name', () {
      expect(InputValidator.validateName('A'), 'En az 2 karakter');
    });

    test('returns error for name with dangerous chars', () {
      // _nameRegex fails first for HTML-like chars, returning 'Geçersiz karakterler'
      expect(InputValidator.validateName('Ah<script>met'), 'Geçersiz karakterler');
    });
  });

  group('InputValidator.validatePhone', () {
    test('returns null for valid Turkish phone', () {
      expect(InputValidator.validatePhone('05321234567'), isNull);
      expect(InputValidator.validatePhone('+905321234567'), isNull);
    });

    test('returns error for invalid phone', () {
      expect(InputValidator.validatePhone('123'), isNotNull);
    });
  });

  group('InputValidator.normalizePhone', () {
    test('normalizes Turkish mobile numbers', () {
      expect(InputValidator.normalizePhone('05321234567'), '+905321234567');
      expect(InputValidator.normalizePhone('5321234567'), '+905321234567');
      expect(InputValidator.normalizePhone('+905321234567'), '+905321234567');
    });
  });

  group('InputValidator.sanitize', () {
    test('removes dangerous characters', () {
      expect(InputValidator.sanitize('<script>alert(1)</script>'), 'scriptalert1/script');
    });

    test('trims whitespace', () {
      expect(InputValidator.sanitize('  hello  world  '), 'hello world');
    });
  });

  group('InputValidator.validateNotEmpty', () {
    test('returns null for non-empty value', () {
      expect(InputValidator.validateNotEmpty('test'), isNull);
    });

    test('returns error for empty value', () {
      expect(InputValidator.validateNotEmpty(''), 'Bu alan zorunlu');
      expect(InputValidator.validateNotEmpty(null), 'Bu alan zorunlu');
    });

    test('uses custom field name', () {
      expect(
        InputValidator.validateNotEmpty('', fieldName: 'İsim'),
        'İsim zorunlu',
      );
    });
  });

  group('InputValidator.stripHtml', () {
    test('removes HTML tags', () {
      expect(InputValidator.stripHtml('<p>Hello</p>'), 'Hello');
      expect(InputValidator.stripHtml('<div><span>Text</span></div>'), 'Text');
    });
  });
}
