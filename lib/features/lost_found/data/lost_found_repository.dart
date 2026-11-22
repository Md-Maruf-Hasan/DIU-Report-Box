import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/lost_found_model.dart';
import '../../../core/services/supabase_storage_service.dart';

class LostFoundRepository {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storage;
  final FirebaseAuth _auth;

  LostFoundRepository({
    FirebaseFirestore? firestore,
    SupabaseStorageService? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? SupabaseStorageService(),
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<LostFoundModel>> watchFeed({
    String? typeFilter, // null, 'lost', 'found', 'resolved'
    String? categoryFilter,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('lostFound');

    if (typeFilter == 'resolved') {
      query = query.where('status', isEqualTo: 'resolved');
    } else {
      query = query.where('status', isEqualTo: 'open');
      if (typeFilter != null && typeFilter != 'all') {
        query = query.where('type', isEqualTo: typeFilter);
      }
    }

    if (categoryFilter != null && categoryFilter != 'all') {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LostFoundModel.fromFirestore(doc))
          .toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return list
            .where((item) =>
                item.title.toLowerCase().contains(q) ||
                item.description.toLowerCase().contains(q))
            .toList();
      }
      return list;
    });
  }

  Future<void> createPost({
    required String type,
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required List<File> imageFiles,
    String? contact,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final authorName = userDoc.data()?['name'] ?? 'Student';

    final docRef = _firestore.collection('lostFound').doc();
    final postId = docRef.id;

    // Upload up to 3 images to Supabase Storage
    final List<String> imageUrls = [];
    for (int i = 0; i < imageFiles.length && i < 3; i++) {
      final file = imageFiles[i];
      final url = await _storage.uploadFile(
        file: file,
        folder: 'lostFound/$postId',
        contentType: 'image/jpeg',
      );
      imageUrls.add(url);
    }

    final post = LostFoundModel(
      id: postId,
      type: type,
      title: title,
      description: description,
      category: category,
      location: location,
      date: date,
      imageUrls: imageUrls,
      contact: contact,
      status: 'open',
      authorUid: user.uid,
      authorName: authorName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(post.toMap());
  }

  Future<void> markResolved(String postId) async {
    await _firestore.collection('lostFound').doc(postId).update({
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('lostFound').doc(postId).delete();
  }

  Future<void> reportContent({
    required String targetId,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('moderationReports').add({
      'targetType': 'lostFound',
      'targetId': targetId,
      'reason': reason,
      'byUid': user.uid,
      'handled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
