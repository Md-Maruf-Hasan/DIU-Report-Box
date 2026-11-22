import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/report_model.dart';
import '../../../core/services/supabase_storage_service.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final SupabaseStorageService _storage;
  final FirebaseAuth _auth;

  ReportRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    SupabaseStorageService? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _storage = storage ?? SupabaseStorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<DepartmentModel>> watchDepartments() {
    return _firestore.collection('departments').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => DepartmentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<RoomModel>> watchRooms(String departmentId) {
    if (departmentId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('departments')
        .doc(departmentId)
        .collection('rooms')
        .orderBy('roomNo')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList());
  }

  Stream<List<ReportModel>> watchMyReports() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('reports')
        .where('reporterUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ReportNoteModel>> watchReportNotes(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('notes')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportNoteModel.fromFirestore(doc))
            .toList());
  }

  Future<bool> checkExistingSimilarReport(
      String departmentId, String roomNo, String category) async {
    try {
      final snap = await _firestore
          .collection('reports')
          .where('departmentId', isEqualTo: departmentId)
          .where('roomNo', isEqualTo: roomNo)
          .where('category', isEqualTo: category)
          .where('status', whereIn: ['submitted', 'sms_sent', 'in_progress'])
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> submitReport({
    required String departmentId,
    required String roomId,
    required String roomNo,
    required String category,
    required String description,
    required List<File> imageFiles,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to submit a report.');

    // Upload up to 3 images to Supabase Storage
    final tempReportId = const Uuid().v4();
    final List<String> imageUrls = [];

    for (int i = 0; i < imageFiles.length && i < 3; i++) {
      final file = imageFiles[i];
      final url = await _storage.uploadFile(
        file: file,
        folder: 'reports/$tempReportId',
        contentType: 'image/jpeg',
      );
      imageUrls.add(url);
    }

    // Call Cloud Function callable (enforces 5 reports / 24h limit & sets R-XXXX)
    final callable = _functions.httpsCallable('createReport');
    final result = await callable.call({
      'departmentId': departmentId,
      'roomId': roomId,
      'roomNo': roomNo,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    return data['refNo'] as String? ?? 'R-Submitted';
  }
}
