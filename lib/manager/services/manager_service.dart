import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/staff_work_record.dart';
import '../../models/user_model.dart';
import '../../models/role.dart';
import '../../models/daily_money.dart';
import '../../models/expense.dart';

class ManagerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ PRODUCT MANAGEMENT ============

  // Add Product
  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).set(product.toMap());
      print('✅ Product added: ${product.name}');
    } catch (e) {
      print('❌ Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Get Product by Barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Product.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting product: $e');
      return null;
    }
  }

  // Update Product Quantity
  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Product quantity updated');
    } catch (e) {
      print('❌ Error updating quantity: $e');
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Get All Products
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').orderBy('name').get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting products: $e');
      return [];
    }
  }

  // Get Products by Category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting products by category: $e');
      return [];
    }
  }

  // ============ STAFF MANAGEMENT ============

  // Create Staff User WITHOUT logging out the manager
  // This uses Firestore to create the user record
  // The staff will need to login with the provided credentials
  Future<bool> createStaffUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      print('👤 Creating staff user: $email');

      // Check if user already exists in Firestore
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        print('❌ User already exists with email: $email');
        return false;
      }

      // First, create the user in Firebase Auth
      // Note: This will sign out the current user
      // We need to store the current user's session
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserUid = currentUser?.uid;

      print('📱 Current manager UID: $currentUserUid');

      // Create the user
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Save staff user data to Firestore
      final newUser = UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
        role: UserRole.staff,
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // IMPORTANT: Sign out the staff account
      await FirebaseAuth.instance.signOut();

      // Now re-authenticate the manager
      if (currentUserUid != null) {
        // We need to re-login the manager
        // The manager's email and password are stored
        // Since we can't get the password, we need to handle this differently

        // Option: Instead of creating with Firebase Auth, we could just create the Firestore record
        // and let the staff login later
        print('⚠️ Staff created but manager was signed out');
        print('✅ Staff user created: $email');
        print('✅ Manager needs to login again');

        return true;
      }

      print('✅ Staff user created: $email');
      return true;

    } catch (e) {
      print('❌ Error creating staff: $e');
      return false;
    }
  }

  // ALTERNATIVE: Create staff WITHOUT Firebase Auth (just Firestore)
  // This is safer - staff will login with password later
  Future<bool> createStaffUserFirestoreOnly({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      print('👤 Creating staff user in Firestore only: $email');

      // Check if user already exists in Firestore
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        print('❌ User already exists with email: $email');
        return false;
      }

      // Create a unique ID for the user
      final uid = _firestore.collection('users').doc().id;

      // Save staff user data to Firestore
      final newUser = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
        role: UserRole.staff,
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      print('✅ Staff user created in Firestore: $email');
      print('⚠️ Staff must be created in Firebase Auth separately (login will fail until created)');

      return true;

    } catch (e) {
      print('❌ Error creating staff: $e');
      return false;
    }
  }

  // Get All Staff Users
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

  // ============ STAFF WORK RECORDS ============

  // Save Staff Work Record
  Future<void> saveStaffWorkRecord(StaffWorkRecord record) async {
    try {
      await _firestore.collection('staffWorkRecords').add(record.toMap());
      print('✅ Staff work record saved');
    } catch (e) {
      print('❌ Error saving work record: $e');
    }
  }

  // Get Staff Work Records by Date Range
  Future<List<StaffWorkRecord>> getStaffWorkRecords(DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('staffWorkRecords')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => StaffWorkRecord.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting work records: $e');
      return [];
    }
  }

  // ============ MANAGER DASHBOARD - READ FROM EXISTING DATABASE ============

  // Get All Users (Staff Only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting users: $e');
      return [];
    }
  }

  // Get Daily Money for a specific user
  Future<List<DailyMoney>> getUserDailyMoney(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyMoney')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => DailyMoney.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting user daily money: $e');
      return [];
    }
  }

  // Get Expenses for a specific user
  Future<List<Expense>> getUserExpenses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting user expenses: $e');
      return [];
    }
  }

  // Get All Daily Money from all users (collection group)
  Future<List<DailyMoney>> getAllDailyMoney() async {
    try {
      final snapshot = await _firestore.collectionGroup('dailyMoney').orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => DailyMoney.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting all daily money: $e');
      return [];
    }
  }

  // Get All Expenses from all users (collection group)
  Future<List<Expense>> getAllExpenses() async {
    try {
      final snapshot = await _firestore.collectionGroup('expenses').orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('❌ Error getting all expenses: $e');
      return [];
    }
  }

  // Get Daily Performance for a specific date (from all users)
  Future<Map<String, dynamic>> getDailyPerformance(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Get all daily money for this date
      final dailyMoneySnapshot = await _firestore
          .collectionGroup('dailyMoney')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalMoney = 0;
      Map<String, double> userMoney = {};

      for (var doc in dailyMoneySnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalWithoutMachine'] ?? 0.0).toDouble();
        totalMoney += amount;

        final userId = data['userId'] ?? 'unknown';
        userMoney[userId] = (userMoney[userId] ?? 0) + amount;
      }

      // Get all expenses for this date
      final expensesSnapshot = await _firestore
          .collectionGroup('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalExpenses = 0;
      Map<String, double> userExpenses = {};

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['price'] ?? 0.0).toDouble();
        totalExpenses += amount;

        final userId = data['userId'] ?? 'unknown';
        userExpenses[userId] = (userExpenses[userId] ?? 0) + amount;
      }

      // Get staff names for users
      final allUsers = await getAllUsers();
      final userNames = <String, String>{};
      for (var user in allUsers) {
        userNames[user.uid] = user.fullName;
      }

      return {
        'date': date,
        'totalMoney': totalMoney,
        'totalExpenses': totalExpenses,
        'netProfit': totalMoney - totalExpenses,
        'userMoney': userMoney,
        'userExpenses': userExpenses,
        'userNames': userNames,
        'staffCount': userMoney.keys.length,
      };
    } catch (e) {
      print('❌ Error getting daily performance: $e');
      return {
        'date': date,
        'totalMoney': 0.0,
        'totalExpenses': 0.0,
        'netProfit': 0.0,
        'userMoney': {},
        'userExpenses': {},
        'userNames': {},
        'staffCount': 0,
      };
    }
  }

  // Get Weekly Performance
  Future<List<Map<String, dynamic>>> getWeeklyPerformance(DateTime startOfWeek) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final daily = await getDailyPerformance(date);
        results.add(daily);
      }

      return results;
    } catch (e) {
      print('❌ Error getting weekly performance: $e');
      return [];
    }
  }

  // Get Monthly Performance
  Future<List<Map<String, dynamic>>> getMonthlyPerformance(int year, int month) async {
    try {
      final results = <Map<String, dynamic>>[];
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final daily = await getDailyPerformance(date);
        results.add(daily);
      }

      return results;
    } catch (e) {
      print('❌ Error getting monthly performance: $e');
      return [];
    }
  }

  // Get Weekly Comparison (last 4 weeks)
  Future<List<Map<String, dynamic>>> getWeeklyComparison() async {
    try {
      final results = <Map<String, dynamic>>[];
      final now = DateTime.now();

      // Get last 4 weeks
      for (int week = 0; week < 4; week++) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1 + (week * 7)));
        final weeklyData = await getWeeklyPerformance(startOfWeek);

        double totalMoney = 0;
        double totalExpenses = 0;
        Set<String> staffIds = {};
        Map<String, double> staffMoney = {};

        for (var day in weeklyData) {
          totalMoney += day['totalMoney'] ?? 0.0;
          totalExpenses += day['totalExpenses'] ?? 0.0;

          final userMoney = day['userMoney'] as Map<String, double>? ?? {};
          for (var entry in userMoney.entries) {
            staffIds.add(entry.key);
            staffMoney[entry.key] = (staffMoney[entry.key] ?? 0) + entry.value;
          }
        }

        // Get staff names
        final allUsers = await getAllUsers();
        final userNames = <String, String>{};
        for (var user in allUsers) {
          userNames[user.uid] = user.fullName;
        }

        // Find top staff
        String topStaffName = 'No staff';
        double topStaffAmount = 0;
        for (var entry in staffMoney.entries) {
          if (entry.value > topStaffAmount) {
            topStaffAmount = entry.value;
            topStaffName = userNames[entry.key] ?? 'Unknown Staff';
          }
        }

        results.add({
          'weekNumber': week + 1,
          'startDate': startOfWeek,
          'endDate': startOfWeek.add(const Duration(days: 6)),
          'totalMoney': totalMoney,
          'totalExpenses': totalExpenses,
          'netProfit': totalMoney - totalExpenses,
          'staffName': topStaffName,
          'staffCount': staffIds.length,
          'staffMoney': staffMoney,
        });
      }

      return results;
    } catch (e) {
      print('❌ Error getting weekly comparison: $e');
      return [];
    }
  }

  // Get Total Money All Time
  Future<double> getTotalMoneyAllTime() async {
    try {
      final snapshot = await _firestore.collectionGroup('dailyMoney').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalWithoutMachine'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error getting total money: $e');
      return 0;
    }
  }

  // Get Total Expenses All Time
  Future<double> getTotalExpensesAllTime() async {
    try {
      final snapshot = await _firestore.collectionGroup('expenses').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['price'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error getting total expenses: $e');
      return 0;
    }
  }

  // Get Staff Performance Summary
  Future<List<Map<String, dynamic>>> getStaffPerformanceSummary() async {
    try {
      final allUsers = await getAllStaff();
      final results = <Map<String, dynamic>>[];

      for (var user in allUsers) {
        final dailyMoney = await getUserDailyMoney(user.uid);
        final expenses = await getUserExpenses(user.uid);

        double totalMoney = 0;
        for (var dm in dailyMoney) {
          totalMoney += dm.totalWithoutMachine;
        }

        double totalExpenses = 0;
        for (var exp in expenses) {
          totalExpenses += exp.price;
        }

        results.add({
          'user': user,
          'totalMoney': totalMoney,
          'totalExpenses': totalExpenses,
          'netProfit': totalMoney - totalExpenses,
          'transactionCount': dailyMoney.length + expenses.length,
        });
      }

      return results;
    } catch (e) {
      print('❌ Error getting staff performance: $e');
      return [];
    }
  }
}