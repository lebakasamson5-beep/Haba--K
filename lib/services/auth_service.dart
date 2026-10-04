import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/role.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _accessDeniedReason;
  bool _needsRedirect = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get accessDeniedReason => _accessDeniedReason;
  bool get needsRedirect => _needsRedirect;

  bool get isManager {
    return _currentUser?.role == UserRole.manager;
  }

  bool get isStaff {
    return _currentUser?.role == UserRole.staff;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    _init();
    _auth.authStateChanges().listen((User? user) {
      print('📡 Auth state changed: ${user?.email ?? 'null'}');
      if (user == null) {
        _isLoggedIn = false;
        _currentUser = null;
        _accessDeniedReason = null;
        _needsRedirect = false;
        notifyListeners();
      } else {
        _loadUserData(user.uid).then((_) {
          _checkAccessAndLogin();
        });
      }
    });
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('userUid');

    if (savedUid != null) {
      try {
        await _loadUserData(savedUid);
        if (_currentUser != null) {
          _checkAccessAndLogin();
        }
      } catch (e) {
        print('❌ Error loading user: $e');
        _isLoggedIn = false;
        await prefs.remove('userUid');
      }
    } else {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
        if (_currentUser != null) {
          _checkAccessAndLogin();
          await prefs.setString('userUid', currentUser.uid);
        }
      } else {
        _isLoggedIn = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.id, doc.data()!);
        print('✅ User data loaded: ${_currentUser?.email}, role: ${_currentUser?.role}');
      } else {
        _currentUser = null;
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      _currentUser = null;
    }
  }

  void _checkAccessAndLogin() {
    if (_currentUser == null) {
      _isLoggedIn = false;
      _accessDeniedReason = 'User not found';
      _needsRedirect = false;
      notifyListeners();
      return;
    }

    // Check if user is Manager - Managers always have access
    if (_currentUser!.role == UserRole.manager) {
      _isLoggedIn = true;
      _accessDeniedReason = null;
      _needsRedirect = false;
      notifyListeners();
      return;
    }

    // Check staff access conditions
    final staff = _currentUser!;

    // 1. Check if approved
    if (!staff.isApproved) {
      _isLoggedIn = false;
      _accessDeniedReason = 'Your account is pending approval. Please wait for the Manager to approve your account.';
      _needsRedirect = true;
      notifyListeners();
      return;
    }

    // 2. Check if locked
    if (staff.isLocked) {
      _isLoggedIn = false;
      _accessDeniedReason = 'Your account has been locked by the Manager. Please contact the Manager for assistance.';
      _needsRedirect = true;
      notifyListeners();
      return;
    }

    // 3. Check if assigned week matches current week
    if (staff.assignedWeek != null) {
      final currentWeek = _getCurrentWeekNumber();
      if (staff.assignedWeek != currentWeek) {
        _isLoggedIn = false;
        _accessDeniedReason = 'It is not your assigned working week. Please wait until your scheduled week.';
        _needsRedirect = true;
        notifyListeners();
        return;
      }
    }

    // All checks passed
    _isLoggedIn = true;
    _accessDeniedReason = null;
    _needsRedirect = false;
    _updateLastLogin();
    notifyListeners();
  }

  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final day = now.day;
    return ((day - 1) ~/ 7) + 1;
  }

  Future<void> _updateLastLogin() async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  // Create Default Manager Account
  Future<void> createDefaultManager() async {
    try {
      const managerEmail = 'Habak@gmail.com';
      const managerPassword = '42Hill';

      print('🔧 Creating/Checking default manager...');

      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: managerEmail,
          password: managerPassword,
        );
        print('✅ Manager already exists in Auth');

        final uid = userCredential.user?.uid;
        if (uid != null) {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            print('✅ Manager data exists in Firestore');
            await _auth.signOut();
            return;
          } else {
            final manager = UserModel(
              uid: uid,
              firstName: 'Habak',
              lastName: 'Manager',
              email: managerEmail,
              createdAt: DateTime.now(),
              role: UserRole.manager,
              isApproved: true,
              isLocked: false,
            );
            await _firestore.collection('users').doc(uid).set(manager.toMap());
            await _auth.signOut();
            return;
          }
        }
        return;
      } catch (e) {
        print('⚠️ Manager does not exist in Auth, creating...');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: managerEmail,
        password: managerPassword,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      await user.updateDisplayName('Habak Manager');

      final manager = UserModel(
        uid: user.uid,
        firstName: 'Habak',
        lastName: 'Manager',
        email: managerEmail,
        createdAt: DateTime.now(),
        role: UserRole.manager,
        isApproved: true,
        isLocked: false,
      );

      await _firestore.collection('users').doc(user.uid).set(manager.toMap());
      await _auth.signOut();

      print('✅ Default manager created: Habak@gmail.com / 42Hill');

    } catch (e) {
      print('❌ Error creating default manager: $e');
    }
  }

  // REGISTER USER (Staff registers themselves)
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'All fields are required'};
    }

    if (password != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    if (password.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      await user.updateDisplayName('$firstName $lastName');

      final newUser = UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
        role: UserRole.staff,
        isApproved: false,
        isLocked: false,
        assignedWeek: null,
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userUid');

      _currentUser = null;
      _isLoggedIn = false;
      _accessDeniedReason = null;
      _needsRedirect = false;

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Account created successfully! You will be able to login once the Manager approves your account.'
      };

    } catch (e) {
      print('❌ Registration error: $e');
      _isLoading = false;
      notifyListeners();

      String errorMessage = 'Registration failed';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email already in use. Please use a different email.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // LOGIN USER
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;

    _isLoading = true;
    notifyListeners();
    _accessDeniedReason = null;
    _needsRedirect = false;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _loadUserData(user.uid);

      if (_currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check access conditions
      _checkAccessAndLogin();

      if (_isLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userUid', user.uid);
      }

      _isLoading = false;
      notifyListeners();

      return _isLoggedIn;

    } catch (e) {
      print('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _isLoggedIn = false;
      _currentUser = null;
      _accessDeniedReason = null;
      _needsRedirect = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userUid');

    } catch (e) {
      print('❌ Logout error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // RESET PASSWORD
  Future<bool> resetPassword(String email) async {
    if (email.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Password reset error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // DELETE STAFF ACCOUNT (Manager only)
  Future<bool> deleteStaffAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('🗑️ Staff account deleted: $uid');
      return true;
    } catch (e) {
      print('❌ Error deleting staff: $e');
      return false;
    }
  }

  User? getFirebaseUser() {
    return _auth.currentUser;
  }
}