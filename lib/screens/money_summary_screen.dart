import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '/app_theme.dart';

class MoneySummaryScreen extends StatefulWidget {
  const MoneySummaryScreen({super.key});

  @override
  State<MoneySummaryScreen> createState() => _MoneySummaryScreenState();
}

class _MoneySummaryScreenState extends State<MoneySummaryScreen> {
  bool _loading = true;
  double _prev = 0, _current = 0, _expenses = 0, _remaining = 0, _combined = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final now = DateTime.now();

    _prev = await db.getPreviousDayMoney(auth.currentUser!.email, now);
    _current = await db.getDailyMoneyByDate(auth.currentUser!.email, now, false);
    _expenses = await db.getExpensesByDate(auth.currentUser!.email, now);
    _remaining = _prev - _expenses;
    _combined = _remaining + _current;

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month, now.day - 1);
    final df = DateFormat('MMMM d, y');

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppTheme.appBar(
        'Money Summary',
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
              _card('Previous Day Money', df.format(prev), _prev, Icons.arrow_back_rounded, AppTheme.neutral),
              const SizedBox(height: 14),
              _card('Current Day Money', df.format(now), _current, Icons.today_rounded, AppTheme.income),
              const SizedBox(height: 14),
              _card('Total Expenses', "Today's expenses", _expenses, Icons.shopping_cart_rounded, AppTheme.expense),
              const SizedBox(height: 14),
              _card('Remaining Money', 'Previous - Expenses', _remaining, Icons.account_balance_rounded, AppTheme.warning),
              const SizedBox(height: 20),
              _combinedCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _combinedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Available Money',
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 10),
                  Text('Combined Balance', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Text(
                AppTheme.currency(_combinedValue),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Remaining previous day money + current day money',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  double get _combinedValue => _combined;

  Widget _card(String title, String subtitle, double amount, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount', style: TextStyle(fontSize: 14, color: AppTheme.textGrey)),
                Text(
                  AppTheme.currency(amount),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}