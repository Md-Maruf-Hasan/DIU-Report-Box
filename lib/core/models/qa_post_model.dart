import 'package:cloud_firestore/cloud_firestore.dart';

class QaPostModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final bool isAnonymous;
  final String? authorUid;
  final String? authorName;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  const QaPostModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.isAnonymous = false,
    this.authorUid,
    this.authorName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  String get displayName => isAnonymous ? 'Anonymous Student' : (authorName ?? 'Student');

  factory QaPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QaPostModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      authorUid: data['authorUid'] as String?,
      authorName: data['authorName'] as String?,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'isAnonymous': isAnonymous,
      'authorUid': isAnonymous ? null : authorUid,
      'authorName': isAnonymous ? null : authorName,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class CommentModel {
  final String id;
  final String text;
  final bool isAnonymous;
  final String? authorUid;
  final String? authorName;
  final DateTime? createdAt;

  const CommentModel({
    required this.id,
    required this.text,
    this.isAnonymous = false,
    this.authorUid,
    this.authorName,
    this.createdAt,
  });

  String get displayName => isAnonymous ? 'Anonymous' : (authorName ?? 'Student');

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: doc.id,
      text: data['text'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      authorUid: data['authorUid'] as String?,
      authorName: data['authorName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isAnonymous': isAnonymous,
      'authorUid': isAnonymous ? null : authorUid,
      'authorName': isAnonymous ? null : authorName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
