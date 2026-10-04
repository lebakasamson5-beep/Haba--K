import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_money.dart';
import '../models/expense.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user ID from auth
  String getUserId(String uid) {
    return uid;
  }

  // CHECK if daily money exists for today
  Future<bool> hasDailyMoneyToday(String uid) async {
    try {
      final userId = getUserId(uid);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking daily money: $e');
      return false;
    }
  }

  // GET today's daily money record
  Future<DailyMoney?> getTodayDailyMoney(String uid) async {
    try {
      final userId = getUserId(uid);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DailyMoney.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting today\'s daily money: $e');
      return null;
    }
  }

  // SAVE Daily Money to Firebase (only if not already saved today)
  Future<Map<String, dynamic>> saveDailyMoney(DailyMoney money) async {
    try {
      final userId = getUserId(money.userId);

      // Check if already saved today
      final alreadySaved = await hasDailyMoneyToday(money.userId);
      if (alreadySaved) {
        return {
          'success': false,
          'message': 'You have already saved daily money for today. You can only save once per day.',
          'alreadySaved': true,
        };
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .add(money.toMap());

      print('✅ Daily money saved to Firebase!');
      return {
        'success': true,
        'message': 'Daily money saved successfully!',
        'alreadySaved': false,
      };
    } catch (e) {
      print('❌ Error saving daily money: $e');
      return {
        'success': false,
        'message': 'Failed to save: $e',
        'alreadySaved': false,
      };
    }
  }

  // UPDATE Daily Money (if not finalized)
  Future<Map<String, dynamic>> updateDailyMoney(String docId, DailyMoney money) async {
    try {
      final userId = getUserId(money.userId);

      // Check if already finalized
      if (money.isFinalized) {
        return {
          'success': false,
          'message': 'This record is finalized and cannot be edited.',
        };
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .doc(docId)
          .update(money.toMap());

      print('✅ Daily money updated!');
      return {
        'success': true,
        'message': 'Daily money updated successfully!',
      };
    } catch (e) {
      print('❌ Error updating daily money: $e');
      return {
        'success': false,
        'message': 'Failed to update: $e',
      };
    }
  }

  // FINALIZE daily money (lock editing)
  Future<Map<String, dynamic>> finalizeDailyMoney(String docId, String uid) async {
    try {
      final userId = getUserId(uid);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .doc(docId)
          .update({
        'isFinalized': true,
      });

      print('✅ Daily money finalized!');
      return {
        'success': true,
        'message': 'Daily money finalized successfully!',
      };
    } catch (e) {
      print('❌ Error finalizing daily money: $e');
      return {
        'success': false,
        'message': 'Failed to finalize: $e',
      };
    }
  }

  // SAVE Expense to Firebase
  Future<void> saveExpense(Expense expense) async {
    try {
      final userId = getUserId(expense.userId);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .add(expense.toMap());
      print('✅ Expense saved to Firebase!');
    } catch (e) {
      print('❌ Error saving expense: $e');
      throw Exception('Failed to save: $e');
    }
  }

  // GET all daily money from Firebase
  Future<List<DailyMoney>> getDailyMoney(String uid) async {
    try {
      final userId = getUserId(uid);
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => DailyMoney.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting daily money: $e');
      return [];
    }
  }

  // GET all expenses from Firebase
  Future<List<Expense>> getExpenses(String uid) async {
    try {
      final userId = getUserId(uid);
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting expenses: $e');
      return [];
    }
  }

  // GET daily money by date
  Future<double> getDailyMoneyByDate(String uid, DateTime date, bool withMachine) async {
    try {
      final userId = getUserId(uid);
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += withMachine
            ? (data['totalWithMachine'] ?? 0.0).toDouble()
            : (data['totalWithoutMachine'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error: $e');
      return 0;
    }
  }

  // GET total expenses by date
  Future<double> getExpensesByDate(String uid, DateTime date) async {
    try {
      final userId = getUserId(uid);
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['price'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error: $e');
      return 0;
    }
  }

  // GET total money all time
  Future<double> getTotalMoney(String uid) async {
    try {
      final userId = getUserId(uid);
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalWithoutMachine'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // GET total expenses all time
  Future<double> getTotalExpenses(String uid) async {
    try {
      final userId = getUserId(uid);
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['price'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // GET previous day money
  Future<double> getPreviousDayMoney(String uid, DateTime currentDate) async {
    final prevDate = DateTime(currentDate.year, currentDate.month, currentDate.day - 1);
    return await getDailyMoneyByDate(uid, prevDate, false);
  }

  // DELETE daily money (for admin/manager)
  Future<void> deleteDailyMoney(String docId, String uid) async {
    try {
      final userId = getUserId(uid);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .doc(docId)
          .delete();
      print('🗑️ Daily money deleted');
    } catch (e) {
      print('❌ Error deleting daily money: $e');
      throw Exception('Failed to delete: $e');
    }
  }
}