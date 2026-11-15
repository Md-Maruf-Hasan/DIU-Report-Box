import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundModel {
  final String id;
  final String type; // 'lost' | 'found'
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final List<String> imageUrls;
  final String? contact;
  final String status; // 'open' | 'resolved'
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LostFoundModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    this.imageUrls = const [],
    this.contact,
    this.status = 'open',
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isResolved => status == 'resolved';

  factory LostFoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LostFoundModel(
      id: doc.id,
      type: data['type'] as String? ?? 'lost',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      location: data['location'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      contact: data['contact'] as String?,
      status: data['status'] as String? ?? 'open',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'date': Timestamp.fromDate(date),
      'imageUrls': imageUrls,
      'contact': contact,
      'status': status,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
