import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String code;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DepartmentModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
    };
  }
}

class RoomModel {
  final String id;
  final String roomNo;
  final String? building;
  final String? floor;

  const RoomModel({
    required this.id,
    required this.roomNo,
    this.building,
    this.floor,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomModel(
      id: doc.id,
      roomNo: data['roomNo'] as String? ?? '',
      building: data['building'] as String?,
      floor: data['floor'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomNo': roomNo,
      'building': building,
      'floor': floor,
    };
  }
}
