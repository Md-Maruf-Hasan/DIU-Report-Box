import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/resource_model.dart';

class ResourceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ResourceRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<ResourceModel>> watchResources({
    required String subsection,
    String? departmentId,
    String? courseCode,
    String? term,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection('resources')
        .where('subsection', isEqualTo: subsection)
        .where('status', isEqualTo: 'approved');

    if (departmentId != null && departmentId != 'all') {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (courseCode != null && courseCode.trim().isNotEmpty) {
      query = query.where('courseCode', isEqualTo: courseCode.trim().toUpperCase());
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ResourceModel.fromFirestore(doc)).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return list.where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.courseCode.toLowerCase().contains(q) ||
            r.courseTitle.toLowerCase().contains(q)).toList();
      }
      return list;
    });
  }

  Future<void> uploadResource({
    required String subsection,
    required String title,
    required String departmentId,
    required String courseCode,
    required String courseTitle,
    required String term,
    String? description,
    required List<File> files, // Images or PDFs
    required List<String> fileKinds, // 'image' | 'pdf'
    String? externalLink,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final uploaderName = userDoc.data()?['name'] ?? 'Student';

    final resourceRef = _firestore.collection('resources').doc();
    final resourceId = resourceRef.id;

    final List<ResourceAttachment> attachments = [];

    // Upload files
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final kind = fileKinds[i];
      final fileName = '${const Uuid().v4()}_${file.path.split(Platform.pathSeparator).last}';
      final storageRef = _storage.ref().child('resources/$resourceId/$fileName');

      final contentType = kind == 'image' ? 'image/jpeg' : 'application/pdf';
      final task = await storageRef.putFile(file, SettableMetadata(contentType: contentType));
      final url = await task.ref.getDownloadURL();
      final size = await file.length();

      attachments.add(ResourceAttachment(
        kind: kind,
        url: url,
        name: file.path.split(Platform.pathSeparator).last,
        sizeBytes: size,
      ));
    }

    // Add external link if provided
    if (externalLink != null && externalLink.trim().isNotEmpty) {
      attachments.add(ResourceAttachment(
        kind: 'link',
        url: externalLink.trim(),
        name: 'External Drive/Resource Link',
      ));
    }

    final resource = ResourceModel(
      id: resourceId,
      subsection: subsection,
      title: title.trim(),
      departmentId: departmentId,
      courseCode: courseCode.trim().toUpperCase(),
      courseTitle: courseTitle.trim(),
      term: term.trim(),
      description: description?.trim(),
      attachments: attachments,
      uploaderUid: user.uid,
      uploaderName: uploaderName,
      status: 'approved', // Auto-approved or set pending if config requires
      createdAt: DateTime.now(),
    );

    await resourceRef.set(resource.toMap());
  }

  Future<void> deleteResource(String resourceId) async {
    await _firestore.collection('resources').doc(resourceId).delete();
  }

  Future<void> reportResource(String resourceId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('moderationReports').add({
      'targetType': 'resource',
      'targetId': resourceId,
      'reason': reason,
      'byUid': user.uid,
      'handled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
