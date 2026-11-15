import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/report_model.dart';
import '../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

final departmentsProvider = StreamProvider<List<DepartmentModel>>((ref) {
  return ref.watch(reportRepositoryProvider).watchDepartments();
});

final roomsForDepartmentProvider =
    StreamProvider.family<List<RoomModel>, String>((ref, departmentId) {
  return ref.watch(reportRepositoryProvider).watchRooms(departmentId);
});

final myReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(reportRepositoryProvider).watchMyReports();
});

final reportNotesProvider =
    StreamProvider.family<List<ReportNoteModel>, String>((ref, reportId) {
  return ref.watch(reportRepositoryProvider).watchReportNotes(reportId);
});

class ReportController extends StateNotifier<AsyncValue<void>> {
  final ReportRepository _repo;

  ReportController(this._repo) : super(const AsyncValue.data(null));

  Future<String?> submitReport({
    required String departmentId,
    required String roomId,
    required String roomNo,
    required String category,
    required String description,
    required List<File> imageFiles,
  }) async {
    state = const AsyncValue.loading();
    try {
      final refNo = await _repo.submitReport(
        departmentId: departmentId,
        roomId: roomId,
        roomNo: roomNo,
        category: category,
        description: description,
        imageFiles: imageFiles,
      );
      state = const AsyncValue.data(null);
      return refNo;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> checkSimilar(String departmentId, String roomNo, String category) async {
    return await _repo.checkExistingSimilarReport(departmentId, roomNo, category);
  }
}

final reportControllerProvider =
    StateNotifierProvider<ReportController, AsyncValue<void>>((ref) {
  return ReportController(ref.watch(reportRepositoryProvider));
});
