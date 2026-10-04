import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/role.dart';

class StaffApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Maximum number of approved staff
  static const int MAX_APPROVED_STAFF = 10;

  // Get all staff users (including unapproved)
  Future<List<UserModel>> getAllStaff() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting staff: $e');
      return [];
    }
  }

  // Get approved staff count
  Future<int> getApprovedStaffCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .where('isApproved', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting approved staff count: $e');
      return 0;
    }
  }

  // Approve a staff member
  Future<bool> approveStaff(String uid) async {
    try {
      // Check if max approved limit reached
      final approvedCount = await getApprovedStaffCount();
      if (approvedCount >= MAX_APPROVED_STAFF) {
        print('❌ Staff limit reached: $approvedCount/$MAX_APPROVED_STAFF');
        return false;
      }

      await _firestore.collection('users').doc(uid).update({
        'isApproved': true,
        'approvedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Staff approved: $uid');
      return true;
    } catch (e) {
      print('❌ Error approving staff: $e');
      return false;
    }
  }

  // Reject/Unapprove a staff member
  Future<void> rejectStaff(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isApproved': false,
        'approvedAt': null,
      });
      print('✅ Staff rejected: $uid');
    } catch (e) {
      print('❌ Error rejecting staff: $e');
    }
  }

  // Lock a staff account
  Future<void> lockStaff(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isLocked': true,
      });
      print('✅ Staff locked: $uid');
    } catch (e) {
      print('❌ Error locking staff: $e');
    }
  }

  // Unlock a staff account
  Future<void> unlockStaff(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isLocked': false,
      });
      print('✅ Staff unlocked: $uid');
    } catch (e) {
      print('❌ Error unlocking staff: $e');
    }
  }

  // Assign working week to staff (single week)
  Future<void> assignWorkingWeek(String uid, int weekNumber) async {
    try {
      if (weekNumber < 1 || weekNumber > 4) {
        throw Exception('Week must be between 1 and 4');
      }
      await _firestore.collection('users').doc(uid).update({
        'assignedWeek': weekNumber,
      });
      print('✅ Working week assigned: Week $weekNumber');
    } catch (e) {
      print('❌ Error assigning week: $e');
    }
  }

  // Delete unapproved staff after 10 days
  Future<void> autoDeleteUnapprovedStaff() async {
    try {
      final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .where('isApproved', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = DateTime.parse(data['createdAt']);

        if (createdAt.isBefore(tenDaysAgo)) {
          await _firestore.collection('users').doc(doc.id).delete();
          print('🗑️ Auto-deleted unapproved staff: ${data['email']}');
        }
      }
    } catch (e) {
      print('❌ Error auto-deleting unapproved staff: $e');
    }
  }

  // Check if staff can access the system
  Future<bool> canAccessSystem(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isApproved = data['isApproved'] ?? false;
      final isLocked = data['isLocked'] ?? false;

      if (!isApproved || isLocked) return false;

      // Check assigned week
      final assignedWeek = data['assignedWeek'];
      if (assignedWeek != null) {
        final currentWeek = _getCurrentWeekNumber();
        if (assignedWeek != currentWeek) return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking access: $e');
      return false;
    }
  }

  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final day = now.day;
    return ((day - 1) ~/ 7) + 1;
  }
}