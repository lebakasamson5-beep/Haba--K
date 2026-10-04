import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'manager/screens/manager_home.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔥 Firebase initialized');

  final auth = AuthService();
  await auth.createDefaultManager();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
      ],
      child: MaterialApp(
        title: 'Haba K Shop',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/pending-approval': (context) => const PendingApprovalScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    print('🔄 AuthWrapper rebuilding - isLoading: ${auth.isLoading}, isLoggedIn: ${auth.isLoggedIn}, needsRedirect: ${auth.needsRedirect}');

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user needs to be redirected to pending approval
    if (auth.needsRedirect && auth.accessDeniedReason != null) {
      print('⏳ Redirecting to pending approval screen');
      return const PendingApprovalScreen();
    }

    if (auth.isLoggedIn && auth.currentUser != null) {
      print('👤 User logged in: ${auth.currentUser?.email}, Role: ${auth.currentUser?.role}');

      // Check if user is Manager
      if (auth.isManager) {
        print('👔 Routing to Manager Home');
        return const ManagerHome();
      }

      // Check if user is Staff with approved access
      if (auth.isStaff && auth.accessDeniedReason == null) {
        print('👤 Routing to Staff Home');
        return const HomeScreen();
      }
    }

    print('❌ No user logged in, showing login screen');
    return const LoginScreen();
  }
}