enum UserRole {
  manager,
  staff,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.manager:
        return 'manager';
      case UserRole.staff:
        return 'staff';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'manager':
        return UserRole.manager;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.staff;
    }
  }
}