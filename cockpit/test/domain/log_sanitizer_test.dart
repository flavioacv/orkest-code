import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/log_sanitizer.dart';

void main() {
  const sanitizer = LogSanitizer();

  group('LogSanitizer (A05)', () {
    test('sanitizes Bearer tokens in logs', () {
      const raw = 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xyz123abc456';
      final clean = sanitizer.sanitize(raw);
      expect(clean, contains('Bearer [REDACTED_TOKEN]'));
      expect(clean, isNot(contains('eyJhbGciOiJIUzI1Ni')));
    });

    test('sanitizes CLI flags with passwords or secrets', () {
      const raw = 'runner --host=localhost --password=super_secret_123 --api-key=secret_key_456 --verbose';
      final clean = sanitizer.sanitize(raw);
      expect(clean, contains('--password=[REDACTED]'));
      expect(clean, contains('--api-key=[REDACTED]'));
      expect(clean, contains('--host=localhost'));
      expect(clean, isNot(contains('super_secret_123')));
    });

    test('sanitizes JSON password fields', () {
      const raw = '{"user": "admin", "password": "mypassword99", "active": true}';
      final clean = sanitizer.sanitize(raw);
      expect(clean, contains('"password": "[REDACTED]"'));
      expect(clean, isNot(contains('mypassword99')));
    });

    test('sanitizes PEM private keys completely', () {
      const raw = '''
Starting server with key:
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCE7r5m4Xm24qfX5wQd1234567890abcdefghijklmnopqrstuvwxyz==
-----END OPENSSH PRIVATE KEY-----
Server listening on port 8080.
''';
      final clean = sanitizer.sanitize(raw);
      expect(clean, contains('[REDACTED PRIVATE KEY]'));
      expect(clean, isNot(contains('b3BlbnNzaC1rZXktdjE')));
      expect(clean, contains('Server listening on port 8080.'));
    });

    test('sanitizes embedded credentials in connection URLs', () {
      const raw = 'Connecting to postgres://myuser:secretpass123@db.example.com:5432/mydb';
      final clean = sanitizer.sanitize(raw);
      expect(clean, contains('postgres://myuser:[REDACTED]@db.example.com:5432/mydb'));
      expect(clean, isNot(contains('secretpass123')));
    });
  });
}
