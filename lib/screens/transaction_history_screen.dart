import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_money.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _loading = true;
  List<DailyMoney> _money = [];
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    _money = await db.getDailyMoney(auth.currentUser!.email);
    _expenses = await db.getExpenses(auth.currentUser!.email);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppTheme.appBar(
        'Transaction History',
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
          : DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppTheme.deepIndigo,
              child: AppTheme.responsive(
                const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: 'Daily Money', icon: Icon(Icons.payments_outlined, size: 20)),
                    Tab(text: 'Expenses', icon: Icon(Icons.shopping_cart_outlined, size: 20)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _money.isEmpty ? _empty('No daily money records yet') : _moneyList(),
                  _expenses.isEmpty ? _empty('No expenses recorded yet') : _expenseList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 16, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _moneyList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _money.length,
          itemBuilder: (_, i) {
            final r = _money[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMMM d, y').format(r.date), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.income.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          AppTheme.currency(r.totalWithoutMachine),
                          style: const TextStyle(color: AppTheme.income, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _detail('Notes', r.notesTotal),
                  _detail('Coins', r.coinsTotal),
                  _detail('Machine', r.machineAmount),
                  const Divider(height: 20),
                  _detail('Total (With Machine)', r.totalWithMachine, bold: true),
                  _detail('Total (Without Machine)', r.totalWithoutMachine, bold: true),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _expenseList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _expenses.length,
          itemBuilder: (_, i) {
            final e = _expenses[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.itemName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 2),
                        Text(DateFormat('MMMM d, y').format(e.date), style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.expense.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      AppTheme.currency(e.price),
                      style: const TextStyle(color: AppTheme.expense, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detail(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textDark, fontSize: 13)),
          Text(
            AppTheme.currency(value),
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: bold ? AppTheme.primaryIndigo : AppTheme.textDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}