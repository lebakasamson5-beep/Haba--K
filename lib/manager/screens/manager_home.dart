import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/auth_service.dart';
import '/app_theme.dart'; // adjust path to match your project
import 'manager_dashboard.dart';
import 'scan_product_screen.dart';
import 'inventory_screen.dart';
import 'manage_staff_screen.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ManagerDashboard(),
    ScanProductScreen(),
    InventoryScreen(),
    ManageStaffScreen(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Scan Product',
    'Inventory',
    'Manage Staff',
  ];

  Future<void> _confirmLogout(AuthService auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepIndigo, foregroundColor: Colors.white),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.logout();
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Logged out successfully',
          backgroundColor: AppTheme.primaryIndigo,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    auth.currentUser?.fullName ?? 'Manager',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(auth),
          ),
        ],
      ),
      // IndexedStack keeps each tab's scroll position and data alive when
      // switching between them, instead of rebuilding from scratch.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryIndigo.withOpacity(0.15),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryIndigo), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.primaryIndigo), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: AppTheme.primaryIndigo), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppTheme.primaryIndigo), label: 'Staff'),
        ],
      ),
    );
  }
}