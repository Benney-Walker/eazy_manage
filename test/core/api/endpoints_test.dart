import 'package:eazy_manage/core/api/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decodes the query string of an endpoint path back into its parameters.
Map<String, String> queryOf(String path) => Uri.parse(path).queryParameters;

void main() {
  group('ApiConfig.BASE_URL', () {
    test('uses localhost in debug test runs unless API_BASE_URL is defined',
        () {
      const override = String.fromEnvironment('API_BASE_URL');
      if (override.isEmpty) {
        expect(ApiConfig.BASE_URL, '${ApiConfig.LOCAL_URL}/api');
      } else {
        expect(ApiConfig.BASE_URL, '$override/api');
      }
    });
  });

  group('Endpoints query encoding', () {
    test('class names with spaces and ampersands survive the round trip', () {
      final path = Endpoints.addNewClass('JHS 1 & 2', 'STF100001');

      expect(path, startsWith('/admin/v1/add-new-class?'));
      expect(queryOf(path), {
        'gradeName': 'JHS 1 & 2',
        'instructorId': 'STF100001',
      });
    });

    test('passwords with reserved characters are not split or altered', () {
      const password = 'p@ss+word&x=1#tag%';
      final path = Endpoints.resetStaffPassword('STF100002', password);

      expect(queryOf(path)['newPassword'], password);
      expect(queryOf(path)['newPasswordStaffId'], 'STF100002');
    });

    test('view-sba keeps the backend parameter name classId', () {
      final path = Endpoints.viewSba('LVL1', 'SUB1', 'SEM1');

      expect(queryOf(path), {
        'classId': 'LVL1',
        'subjectId': 'SUB1',
        'semesterId': 'SEM1',
      });
    });

    test('multi-parameter endpoints keep every parameter', () {
      expect(
        queryOf(Endpoints.fetchPaymentRecords('STD1', 'LVL1', 'SEM1')),
        {'studentId': 'STD1', 'levelId': 'LVL1', 'semesterId': 'SEM1'},
      );
      expect(
        queryOf(Endpoints.promoteStudent('STD1', 'LVL2', 'SEM3')),
        {'studentId': 'STD1', 'promotionClassId': 'LVL2', 'semesterId': 'SEM3'},
      );
      expect(
        queryOf(Endpoints.timelyLogs('2026-01-01', '2026-01-31')),
        {'fromDate': '2026-01-01', 'toDate': '2026-01-31'},
      );
    });

    test('path-only endpoints are unchanged', () {
      expect(Endpoints.loadStudents('LVL1'), '/student/v1/load-students/LVL1');
      expect(Endpoints.deleteExpenses('EXP1'),
          '/finance/v1/delete-expenses/EXP1');
    });
  });
}
