import 'package:eazy_manage/core/navigation/nav_item.dart';
import 'package:eazy_manage/core/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRole', () {
    test('round-trips every role through its backend value', () {
      for (final role in AppRole.values) {
        expect(AppRole.fromBackend(role.backendValue), role);
      }
    });

    test('parsing is case- and whitespace-insensitive', () {
      expect(AppRole.fromBackend(' accountant '), AppRole.accountant);
      expect(AppRole.fromBackend('Principal'), AppRole.principal);
    });
  });

  group('Session.initials', () {
    Session session(String name) => Session(
          fullName: name,
          organizationName: 'Daffodils International School',
          roles: const [AppRole.principal],
          role: AppRole.principal,
        );

    test('uses first and last name initials', () {
      expect(session('Gertrude Ayensu').initials, 'GA');
      expect(session('kofi  ama  mensah').initials, 'KM');
    });

    test('handles single names and blanks', () {
      expect(session('Ben').initials, 'B');
      expect(session('   ').initials, '?');
    });
  });
}
