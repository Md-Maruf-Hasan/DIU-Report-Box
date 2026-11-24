import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String bio;
  final String? studentId;
  final String departmentId;
  final String role; // 'student' | 'admin'
  final String? photoUrl;
  final List<String> fcmTokens;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.bio = '',
    this.studentId,
    required this.departmentId,
    this.role = 'student',
    this.photoUrl,
    this.fcmTokens = const [],
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      studentId: data['studentId'] as String?,
      departmentId: data['departmentId'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      photoUrl: data['photoUrl'] as String?,
      fcmTokens: List<String>.from(data['fcmTokens'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'studentId': studentId,
      'departmentId': departmentId,
      'role': role,
      'photoUrl': photoUrl,
      'fcmTokens': fcmTokens,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? bio,
    String? studentId,
    String? departmentId,
    String? role,
    String? photoUrl,
    List<String>? fcmTokens,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      studentId: studentId ?? this.studentId,
      departmentId: departmentId ?? this.departmentId,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
