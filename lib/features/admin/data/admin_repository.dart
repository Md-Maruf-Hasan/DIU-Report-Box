import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/models/report_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<Map<String, dynamic>>> watchModerationQueue() {
    return _firestore
        .collection('moderationReports')
        .where('handled', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> resolveModerationReport(String reportId, bool deleteContent, String targetType, String targetId) async {
    if (deleteContent) {
      if (targetType == 'lostFound') {
        await _firestore.collection('lostFound').doc(targetId).delete();
      } else if (targetType == 'qa_post') {
        await _firestore.collection('qaPosts').doc(targetId).delete();
      } else if (targetType == 'resource') {
        await _firestore.collection('resources').doc(targetId).delete();
      }
    }

    await _firestore.collection('moderationReports').doc(reportId).update({
      'handled': true,
      'handledAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ReportModel>> watchAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList());
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
    required String adminUid,
    required String adminName,
    String? noteText,
  }) async {
    final batch = _firestore.batch();
    final reportRef = _firestore.collection('reports').doc(reportId);

    batch.update(reportRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (noteText != null && noteText.trim().isNotEmpty) {
      final noteRef = reportRef.collection('notes').doc();
      batch.set(noteRef, {
        'byUid': adminUid,
        'byName': adminName,
        'text': noteText.trim(),
        'newStatus': newStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<int> retryFailedSms() async {
    final callable = _functions.httpsCallable('retryFailedSms');
    final result = await callable.call();
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['retriedCount'] as int? ?? 0;
  }

  Stream<List<Map<String, dynamic>>> watchDepartmentContacts(String departmentId) {
    return _firestore
        .collection('departments')
        .doc(departmentId)
        .collection('maintenanceContacts')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> saveMaintenanceContact({
    required String departmentId,
    String? contactId,
    required String name,
    required String phone,
    required bool active,
    List<String> categories = const [],
  }) async {
    final contactsCol = _firestore
        .collection('departments')
        .doc(departmentId)
        .collection('maintenanceContacts');

    final docRef = contactId != null ? contactsCol.doc(contactId) : contactsCol.doc();

    await docRef.set({
      'name': name.trim(),
      'phone': phone.trim(),
      'active': active,
      'categories': categories,
    }, SetOptions(merge: true));
  }
}
