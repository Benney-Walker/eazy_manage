import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/session/session.dart';
import 'dashboard_models.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) {
    return const DashboardData();
  }
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.load(session.role);
});
