import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/report_model.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final moderationQueueProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchModerationQueue();
});

final allReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllReports();
});

final departmentContactsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, deptId) {
  return ref.watch(adminRepositoryProvider).watchDepartmentContacts(deptId);
});
