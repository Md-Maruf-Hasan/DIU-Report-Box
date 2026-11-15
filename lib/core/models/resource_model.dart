import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceAttachment {
  final String kind; // 'image' | 'pdf' | 'link'
  final String url;
  final String name;
  final int? sizeBytes;

  const ResourceAttachment({
    required this.kind,
    required this.url,
    required this.name,
    this.sizeBytes,
  });

  factory ResourceAttachment.fromMap(Map<String, dynamic> map) {
    return ResourceAttachment(
      kind: map['kind'] as String? ?? 'link',
      url: map['url'] as String? ?? '',
      name: map['name'] as String? ?? 'Attachment',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kind': kind,
      'url': url,
      'name': name,
      'sizeBytes': sizeBytes,
    };
  }
}

class ResourceModel {
  final String id;
  final String subsection; // 'previous_questions' | 'notes' | 'others'
  final String title;
  final String departmentId;
  final String courseCode;
  final String courseTitle;
  final String term; // e.g. "Fall 2026"
  final String? description;
  final List<ResourceAttachment> attachments;
  final String uploaderUid;
  final String uploaderName;
  final String status; // 'approved' | 'pending'
  final DateTime? createdAt;

  const ResourceModel({
    required this.id,
    required this.subsection,
    required this.title,
    required this.departmentId,
    required this.courseCode,
    required this.courseTitle,
    required this.term,
    this.description,
    this.attachments = const [],
    required this.uploaderUid,
    required this.uploaderName,
    this.status = 'approved',
    this.createdAt,
  });

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawAttachments = data['attachments'] as List? ?? [];
    return ResourceModel(
      id: doc.id,
      subsection: data['subsection'] as String? ?? 'others',
      title: data['title'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      courseCode: data['courseCode'] as String? ?? '',
      courseTitle: data['courseTitle'] as String? ?? '',
      term: data['term'] as String? ?? '',
      description: data['description'] as String?,
      attachments: rawAttachments
          .map((a) => ResourceAttachment.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList(),
      uploaderUid: data['uploaderUid'] as String? ?? '',
      uploaderName: data['uploaderName'] as String? ?? 'Student',
      status: data['status'] as String? ?? 'approved',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subsection': subsection,
      'title': title,
      'departmentId': departmentId,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'term': term,
      'description': description,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'uploaderUid': uploaderUid,
      'uploaderName': uploaderName,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
