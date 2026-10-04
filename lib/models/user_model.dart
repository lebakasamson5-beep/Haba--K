import 'role.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime createdAt;
  final UserRole role;
  final bool isApproved;
  final bool isLocked;
  final DateTime? approvedAt;
  final int? assignedWeek; // 1-4 for weekly rotation
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    this.role = UserRole.staff,
    this.isApproved = false,
    this.isLocked = false,
    this.approvedAt,
    this.assignedWeek,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'role': role.value,
    'isApproved': isApproved,
    'isLocked': isLocked,
    'approvedAt': approvedAt?.toIso8601String(),
    'assignedWeek': assignedWeek,
    'lastLogin': lastLogin?.toIso8601String(),
  };

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
    uid: id,
    firstName: map['firstName'] ?? '',
    lastName: map['lastName'] ?? '',
    email: map['email'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    role: map['role'] != null ? UserRoleExtension.fromString(map['role']) : UserRole.staff,
    isApproved: map['isApproved'] ?? false,
    isLocked: map['isLocked'] ?? false,
    approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
    assignedWeek: map['assignedWeek'],
    lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
  );

  String get fullName => '$firstName $lastName';
  bool get canAccess => isApproved && !isLocked;
}