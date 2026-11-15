import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/qa_post_model.dart';

class QaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  QaRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<QaPostModel>> watchFeed({
    String sortBy = 'newest', // 'newest' | 'active'
    String searchQuery = '',
  }) {
    Query query = _firestore.collection('qaPosts');

    if (sortBy == 'active') {
      query = query.orderBy('commentCount', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => QaPostModel.fromFirestore(doc)).toList();
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return list.where((item) =>
            item.title.toLowerCase().contains(q) || item.body.toLowerCase().contains(q)).toList();
      }
      return list;
    });
  }

  Future<void> createPost({
    required String title,
    required String body,
    required bool isAnonymous,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    String? imageUrl;
    if (imageFile != null) {
      final fileName = '${const Uuid().v4()}.jpg';
      final tempId = const Uuid().v4();
      final storageRef = _storage.ref().child('qa/$tempId/$fileName');
      final uploadTask = await storageRef.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    if (isAnonymous) {
      // Must call Cloud Function to protect identity server-side
      final callable = _functions.httpsCallable('createAnonymousPost');
      await callable.call({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
      });
    } else {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final authorName = userDoc.data()?['name'] ?? 'Student';

      await _firestore.collection('qaPosts').add({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'isAnonymous': false,
        'authorUid': user.uid,
        'authorName': authorName,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<CommentModel>> watchComments(String postId) {
    return _firestore
        .collection('qaPosts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required bool isAnonymous,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    if (isAnonymous) {
      final callable = _functions.httpsCallable('createAnonymousComment');
      await callable.call({
        'postId': postId,
        'text': text,
      });
    } else {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final authorName = userDoc.data()?['name'] ?? 'Student';

      final commentRef = _firestore.collection('qaPosts').doc(postId).collection('comments').doc();

      final batch = _firestore.batch();
      batch.set(commentRef, {
        'text': text,
        'isAnonymous': false,
        'authorUid': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_firestore.collection('qaPosts').doc(postId), {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();
    }
  }

  Stream<bool> isLiked(String postId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _firestore
        .collection('qaPosts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final likeRef = _firestore.collection('qaPosts').doc(postId).collection('likes').doc(user.uid);
    final postRef = _firestore.collection('qaPosts').doc(postId);

    final likeSnap = await likeRef.get();
    if (likeSnap.exists) {
      await likeRef.delete();
      await postRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> deletePost(QaPostModel post) async {
    if (post.isAnonymous) {
      final callable = _functions.httpsCallable('deleteAnonymousPost');
      await callable.call({'postId': post.id});
    } else {
      await _firestore.collection('qaPosts').doc(post.id).delete();
    }
  }

  Future<void> deleteComment(String postId, CommentModel comment) async {
    await _firestore
        .collection('qaPosts')
        .doc(postId)
        .collection('comments')
        .doc(comment.id)
        .delete();
    await _firestore.collection('qaPosts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  Future<void> reportQaContent({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('moderationReports').add({
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'byUid': user.uid,
      'handled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
