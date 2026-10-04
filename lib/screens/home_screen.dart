import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'daily_money_screen.dart';
import 'money_used_screen.dart';
import 'money_summary_screen.dart';
import 'transaction_history_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color deepIndigo = Color(0xFF283593);
  static const Color backgroundGrey = Color(0xFFF5F6FA);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firstName = auth.currentUser?.firstName ?? '';
    final lastName = auth.currentUser?.lastName ?? '';
    final initials = _initials(firstName, lastName);
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    // Menu items defined once so both the grid layout and item count stay in sync.
    final menuItems = [
      _MenuItem('Daily Money', Icons.payments_outlined, primaryIndigo, const DailyMoneyScreen()),
      _MenuItem('Money Used', Icons.shopping_cart_outlined, const Color(0xFF00897B), const MoneyUsedScreen()),
      _MenuItem('Money Summary', Icons.summarize_outlined, const Color(0xFF5E35B1), const MoneySummaryScreen()),
      _MenuItem('Transaction History', Icons.history, const Color(0xFF1E88E5), const TransactionHistoryScreen()),
      _MenuItem('Reports', Icons.bar_chart_outlined, const Color(0xFFE53935), const ReportsScreen()),
      _MenuItem('Settings', Icons.settings_outlined, const Color(0xFF546E7A), null),
    ];

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final crossAxisCount = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 700
                ? 3
                : 2;
            final horizontalPadding = isWide ? 32.0 : 16.0;
            final maxContentWidth = 1100.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        today: today,
                        firstName: firstName,
                        lastName: lastName,
                        initials: initials,
                        horizontalPadding: horizontalPadding,
                        onLogout: () async {
                          final confirmed = await _confirmLogout(context);
                          if (confirmed == true) {
                            await auth.logout();
                            Fluttertoast.showToast(
                              msg: 'Logged out successfully',
                              backgroundColor: deepIndigo,
                              textColor: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.15 : 1.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _MenuTile(item: menuItems[index]),
                          childCount: menuItems.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    final result = (f + l).toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: deepIndigo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;

  _MenuItem(this.title, this.icon, this.color, this.page);
}

class _Header extends StatelessWidget {
  final String today;
  final String firstName;
  final String lastName;
  final String initials;
  final double horizontalPadding;
  final VoidCallback onLogout;

  const _Header({
    required this.today,
    required this.firstName,
    required this.lastName,
    required this.initials,
    required this.horizontalPadding,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeScreen.deepIndigo, HomeScreen.primaryIndigo],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Haba-K',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        'Shop Management',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ProfileMenu(
                initials: initials,
                firstName: firstName,
                lastName: lastName,
                onLogout: onLogout,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  today,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String initials;
  final String firstName;
  final String lastName;
  final VoidCallback onLogout;

  const _ProfileMenu({
    required this.initials,
    required this.firstName,
    required this.lastName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tooltip: 'Account',
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            '$firstName $lastName'.trim().isEmpty ? 'Account' : '$firstName $lastName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Log out'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: CircleAvatar(
          radius: 19,
          backgroundColor: Colors.white,
          child: Text(
            initials,
            style: const TextStyle(
              color: HomeScreen.deepIndigo,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.page == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coming soon!'),
            backgroundColor: HomeScreen.deepIndigo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )
            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page!)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E2C),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: item.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}