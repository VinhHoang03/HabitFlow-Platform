import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/utils/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('validates email input', () {
      expect(FormValidators.email('user@example.com'), isNull);
      expect(FormValidators.email(''), isNotNull);
      expect(FormValidators.email('user example.com'), isNotNull);
      expect(FormValidators.email('user@example'), isNotNull);
    });

    test('validates login and new passwords', () {
      expect(FormValidators.loginPassword('abc123'), isNull);
      expect(FormValidators.loginPassword('123'), isNotNull);
      expect(FormValidators.newPassword('abc123'), isNull);
      expect(FormValidators.newPassword('abcdef'), isNotNull);
      expect(FormValidators.newPassword('123456'), isNotNull);
      expect(FormValidators.newPassword(' abc123'), isNotNull);
    });

    test('validates password confirmation and change rules', () {
      expect(FormValidators.confirmPassword('abc123', 'abc123'), isNull);
      expect(FormValidators.confirmPassword('', 'abc123'), isNotNull);
      expect(FormValidators.confirmPassword('abc124', 'abc123'), isNotNull);
      expect(FormValidators.changedPassword('def456', 'abc123'), isNull);
      expect(FormValidators.changedPassword('abc123', 'abc123'), isNotNull);
    });

    test('validates profile inputs', () {
      expect(FormValidators.displayName('Nguyen Van A'), isNull);
      expect(FormValidators.displayName('A'), isNotNull);
      expect(FormValidators.displayName('Invalid<Name'), isNotNull);
      expect(
        FormValidators.avatarUrl('https://example.com/avatar.png'),
        isNull,
      );
      expect(FormValidators.avatarUrl(''), isNull);
      expect(
        FormValidators.avatarUrl('ftp://example.com/avatar.png'),
        isNotNull,
      );
    });
  });

  test('source files do not contain common mojibake markers', () {
    final mojibakeMarkers = [
      String.fromCharCode(0x00c3),
      String.fromCharCode(0x00c2),
      String.fromCharCode(0x00c4),
      String.fromCharCode(0x00c6),
      String.fromCharCodes([0x00e1, 0x00ba]),
      String.fromCharCodes([0x00e1, 0x00bb]),
      String.fromCharCodes([0x00e2, 0x20ac]),
      String.fromCharCode(0xfffd),
    ];
    final mojibakePattern = RegExp(
      mojibakeMarkers.map(RegExp.escape).join('|'),
    );
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final affectedFiles = <String>[];
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      if (mojibakePattern.hasMatch(content)) {
        affectedFiles.add(file.path);
      }
    }

    expect(affectedFiles, isEmpty, reason: affectedFiles.join('\n'));
  });
}
