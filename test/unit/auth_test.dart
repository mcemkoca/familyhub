import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyhub/domain/entities.dart';
import 'package:familyhub/core/validation/input_validator.dart';

void main() {
  group('Auth & Family Entities', () {
    test('FamilyMember creation', () {
      const member = FamilyMember(
        id: 'm1',
        name: 'Mustafa',
        initial: 'M',
        color: Color(0xFF3B82F6),
        role: MemberRole.admin,
        isOnline: true,
      );
      expect(member.name, 'Mustafa');
      expect(member.role, MemberRole.admin);
      expect(member.isOnline, true);
    });

    test('Task copyWith changes status', () {
      const task = Task(id: '1', title: 'Test', assignedTo: 'm1');
      final updated = task.copyWith(status: TaskStatus.completed);
      expect(updated.status, TaskStatus.completed);
      expect(updated.title, 'Test');
    });

    test('ChatMessage copyWith', () {
      final msg = ChatMessage(
        id: '1',
        senderId: 'm1',
        senderName: 'Mustafa',
        senderColor: const Color(0xFF3B82F6),
        content: 'Merhaba',
        createdAt: DateTime.now(),
      );
      final updated = msg.copyWith(content: 'Güncel');
      expect(updated.content, 'Güncel');
      expect(updated.senderName, 'Mustafa');
    });
  });

  group('InputValidator', () {
    test('validateEmail rejects empty input', () {
      expect(InputValidator.validateEmail(''), isNotNull);
    });

    test('validateEmail rejects invalid format', () {
      expect(InputValidator.validateEmail('not-an-email'), isNotNull);
      expect(InputValidator.validateEmail('test@'), isNotNull);
      expect(InputValidator.validateEmail('@example.com'), isNotNull);
    });

    test('validateEmail accepts valid format', () {
      expect(InputValidator.validateEmail('test@example.com'), isNull);
      expect(InputValidator.validateEmail('user.name@domain.co.tr'), isNull);
    });

    test('validatePassword rejects empty input', () {
      expect(InputValidator.validatePassword(''), isNotNull);
    });

    test('validatePassword rejects short passwords', () {
      expect(InputValidator.validatePassword('12345'), isNotNull);
    });

    test('validatePassword accepts strong passwords', () {
      expect(InputValidator.validatePassword('StrongPass123!'), isNull);
    });

    test('validateName rejects empty input', () {
      expect(InputValidator.validateName(''), isNotNull);
    });

    test('validateName rejects overly long names', () {
      expect(InputValidator.validateName('A' * 51), isNotNull);
    });

    test('validateName accepts valid names', () {
      expect(InputValidator.validateName('Ahmet'), isNull);
    });

    test('validatePhone rejects invalid formats', () {
      expect(InputValidator.validatePhone('123'), isNotNull);
      expect(InputValidator.validatePhone('abc'), isNotNull);
    });

    test('validatePhone accepts valid formats', () {
      expect(InputValidator.validatePhone('05551234567'), isNull);
      expect(InputValidator.validatePhone('+905551234567'), isNull);
    });

    test('validateNotEmpty rejects empty input', () {
      expect(InputValidator.validateNotEmpty(''), isNotNull);
      expect(InputValidator.validateNotEmpty(null), isNotNull);
    });

    test('validateNotEmpty accepts non-empty input', () {
      expect(InputValidator.validateNotEmpty('value'), isNull);
    });

    test('validateMaxLength rejects overly long input', () {
      expect(InputValidator.validateMaxLength('a' * 11, 10), isNotNull);
    });

    test('validateMaxLength accepts short input', () {
      expect(InputValidator.validateMaxLength('a' * 10, 10), isNull);
    });
  });
}
