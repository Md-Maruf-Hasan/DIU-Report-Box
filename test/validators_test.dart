import 'package:flutter_test/flutter_test.dart';
import 'package:diu_report_box/core/validators.dart';

void main() {
  group('Validators Test Suite', () {
    test('Email domain validation allows @diu.edu.bd only', () {
      expect(Validators.validateEmail('student@diu.edu.bd'), isNull);
      expect(Validators.validateEmail('john.swe@diu.edu.bd'), isNull);

      // Non-university emails must fail
      expect(Validators.validateEmail('student@gmail.com'), contains('Only university email'));
      expect(Validators.validateEmail('student@yahoo.com'), contains('Only university email'));
      expect(Validators.validateEmail('student@other.edu'), contains('Only university email'));
      expect(Validators.validateEmail(''), contains('Email is required'));
    });

    test('Password validation enforces min 8 chars with letter and number', () {
      expect(Validators.validatePassword('Password123'), isNull);
      expect(Validators.validatePassword('Diu2026Secure'), isNull);

      // Too short (< 8 chars)
      expect(Validators.validatePassword('Pass1'), contains('at least 8 characters'));
      // Only letters
      expect(Validators.validatePassword('OnlyLettersHere'), contains('at least one letter and one number'));
      // Only numbers
      expect(Validators.validatePassword('123456789'), contains('at least one letter and one number'));
    });

    test('Report description validation enforces min 15 chars', () {
      expect(Validators.validateReportDescription('PC #4 is not turning on in Lab 703'), isNull);
      expect(Validators.validateReportDescription('Short'), contains('at least 15 characters'));
      expect(Validators.validateReportDescription(''), contains('Description is required'));
    });

    test('URL validator enforces valid https:// link', () {
      expect(Validators.validateHttpsUrl('https://drive.google.com/file/d/123'), isNull);
      expect(Validators.validateHttpsUrl('http://insecure.com'), contains('https://'));
      expect(Validators.validateHttpsUrl('not-a-url'), contains('https://'));
    });
  });
}
