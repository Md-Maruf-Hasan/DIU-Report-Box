import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String refNo;
  final String reporterUid;
  final String reporterName;
  final String departmentId;
  final String roomId;
  final String roomNo;
  final String category;
  final String description;
  final List<String> imageUrls;
  final String status; // 'submitted' | 'sms_sent' | 'in_progress' | 'resolved' | 'rejected'
  final String smsStatus; // 'pending' | 'sent' | 'failed'
  final int smsAttempts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    required this.refNo,
    required this.reporterUid,
    required this.reporterName,
    required this.departmentId,
    required this.roomId,
    required this.roomNo,
    required this.category,
    required this.description,
    this.imageUrls = const [],
    this.status = 'submitted',
    this.smsStatus = 'pending',
    this.smsAttempts = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel(
      id: doc.id,
      refNo: data['refNo'] as String? ?? 'R-0000',
      reporterUid: data['reporterUid'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? 'Student',
      departmentId: data['departmentId'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      roomNo: data['roomNo'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      status: data['status'] as String? ?? 'submitted',
      smsStatus: data['smsStatus'] as String? ?? 'pending',
      smsAttempts: (data['smsAttempts'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'refNo': refNo,
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'departmentId': departmentId,
      'roomId': roomId,
      'roomNo': roomNo,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
      'status': status,
      'smsStatus': smsStatus,
      'smsAttempts': smsAttempts,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class ReportNoteModel {
  final String id;
  final String byUid;
  final String byName;
  final String text;
  final String? newStatus;
  final DateTime? createdAt;

  const ReportNoteModel({
    required this.id,
    required this.byUid,
    required this.byName,
    required this.text,
    this.newStatus,
    this.createdAt,
  });

  factory ReportNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportNoteModel(
      id: doc.id,
      byUid: data['byUid'] as String? ?? '',
      byName: data['byName'] as String? ?? 'Staff',
      text: data['text'] as String? ?? '',
      newStatus: data['newStatus'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'byUid': byUid,
      'byName': byName,
      'text': text,
      'newStatus': newStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
