import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  double _totalMoney = 0, _totalExpenses = 0, _net = 0;
  Map<String, Map<String, double>> _daily = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    _totalMoney = await db.getTotalMoney(auth.currentUser!.email);
    _totalExpenses = await db.getTotalExpenses(auth.currentUser!.email);
    _net = _totalMoney - _totalExpenses;

    final money = await db.getDailyMoney(auth.currentUser!.email);
    final expenses = await db.getExpenses(auth.currentUser!.email);

    final daily = <String, Map<String, double>>{};
    for (var m in money) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      daily.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      daily[key]!['income'] = (daily[key]!['income'] ?? 0) + m.totalWithoutMachine;
    }
    for (var e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      daily.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      daily[key]!['expense'] = (daily[key]!['expense'] ?? 0) + e.price;
    }
    _daily = daily;

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppTheme.appBar(
        'Reports',
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppTheme.responsive(
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepIndigo.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _summaryRow('Total Money Collected', _totalMoney, Icons.attach_money_rounded),
                    const Divider(height: 28, color: Colors.white24),
                    _summaryRow('Total Expenses', _totalExpenses, Icons.shopping_cart_rounded),
                    const Divider(height: 28, color: Colors.white24),
                    _summaryRow('Net Money', _net, Icons.account_balance_rounded, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _dailyBreakdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, double amount, IconData icon, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        Text(
          AppTheme.currency(amount),
          style: TextStyle(
            color: Colors.white,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 20 : 16,
          ),
        ),
      ],
    );
  }

  Widget _dailyBreakdown() {
    if (_daily.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No data available', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    final sorted = _daily.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              final key = sorted[i];
              final data = _daily[key]!;
              final income = data['income'] ?? 0;
              final expense = data['expense'] ?? 0;
              final net = income - expense;
              final date = DateTime.parse(key);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMMM d, y').format(date), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (net >= 0 ? AppTheme.income : AppTheme.expense).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Net: ${AppTheme.currency(net)}',
                            style: TextStyle(
                              color: net >= 0 ? AppTheme.income : AppTheme.expense,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('Income', income, AppTheme.income),
                        _miniStat('Expense', expense, AppTheme.expense),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        const SizedBox(height: 2),
        Text(AppTheme.currency(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}