import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_money.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class DailyMoneyScreen extends StatefulWidget {
  const DailyMoneyScreen({super.key});

  @override
  State<DailyMoneyScreen> createState() => _DailyMoneyScreenState();
}

class _DailyMoneyScreenState extends State<DailyMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _coins = TextEditingController();
  final _machine = TextEditingController();
  bool _loading = false;
  bool _alreadySavedToday = false;
  DailyMoney? _existingRecord;
  double _totalWM = 0, _totalWoM = 0;

  // Theme Colors
  static const Color deepIndigo = Color(0xFF1A237E);
  static const Color primaryIndigo = Color(0xFF3949AB);
  static const Color backgroundGrey = Color(0xFFF5F7FA);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);

  void _calc() => setState(() {
    final n = double.tryParse(_notes.text) ?? 0;
    final c = double.tryParse(_coins.text) ?? 0;
    final m = double.tryParse(_machine.text) ?? 0;
    _totalWM = n + c + m;
    _totalWoM = n + c;
  });

  Future<void> _checkExistingRecord() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final record = await db.getTodayDailyMoney(auth.currentUser!.uid);
    if (record != null) {
      setState(() {
        _existingRecord = record;
        _alreadySavedToday = true;
        _notes.text = record.notesTotal.toString();
        _coins.text = record.coinsTotal.toString();
        _machine.text = record.machineAmount.toString();
        _calc();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final now = DateTime.now();

      if (_alreadySavedToday) {
        Fluttertoast.showToast(
          msg: '⚠️ You have already saved daily money for today!',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() => _loading = false);
        return;
      }

      final dailyMoney = DailyMoney(
        id: '',
        userId: auth.currentUser!.uid,
        date: now,
        notesTotal: double.parse(_notes.text),
        coinsTotal: double.parse(_coins.text),
        machineAmount: double.parse(_machine.text),
        totalWithMachine: _totalWM,
        totalWithoutMachine: _totalWoM,
        timestamp: now,
        isFinalized: false,
      );

      final result = await db.saveDailyMoney(dailyMoney);

      if (result['success']) {
        Fluttertoast.showToast(
          msg: '✅ Daily money saved!',
          backgroundColor: income,
          textColor: Colors.white,
        );
        _notes.clear();
        _coins.clear();
        _machine.clear();
        _calc();
        setState(() {
          _alreadySavedToday = true;
        });
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? '❌ Error saving',
          backgroundColor: expense,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        if (result['alreadySaved'] == true) {
          setState(() {
            _alreadySavedToday = true;
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '❌ Error: $e',
        backgroundColor: expense,
        textColor: Colors.white,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _notes.addListener(_calc);
    _coins.addListener(_calc);
    _machine.addListener(_calc);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingRecord();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    _coins.dispose();
    _machine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userName = auth.currentUser?.fullName ?? 'User';

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text('Daily Money'),
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // User greeting
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF3949AB),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $userName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_alreadySavedToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '✅ Saved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Info Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _alreadySavedToday
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _alreadySavedToday
                                ? Colors.green.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _alreadySavedToday
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _alreadySavedToday
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _alreadySavedToday
                                    ? '✅ Today\'s daily money has been saved. You can only save once per day.'
                                    : '📝 Enter today\'s money amounts. You can save only once per day.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _alreadySavedToday
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes Field
                      TextFormField(
                        controller: _notes,
                        decoration: _inputDecoration('Notes (R)', Icons.receipt_long_rounded),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        enabled: !_alreadySavedToday,
                      ),
                      const SizedBox(height: 16),

                      // Coins Field
                      TextFormField(
                        controller: _coins,
                        decoration: _inputDecoration('Coins (R)', Icons.monetization_on_outlined),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        enabled: !_alreadySavedToday,
                      ),
                      const SizedBox(height: 16),

                      // Machine Field
                      TextFormField(
                        controller: _machine,
                        decoration: _inputDecoration('Machine (R)', Icons.point_of_sale_rounded),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        enabled: !_alreadySavedToday,
                      ),
                      const SizedBox(height: 24),

                      // Summary Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _row('Notes', _notes.text.isEmpty ? 0 : double.tryParse(_notes.text) ?? 0),
                            _row('Coins', _coins.text.isEmpty ? 0 : double.tryParse(_coins.text) ?? 0),
                            _row('Machine', _machine.text.isEmpty ? 0 : double.tryParse(_machine.text) ?? 0),
                            const Divider(height: 22, color: Colors.white24),
                            _row('Total (With Machine)', _totalWM, bold: true),
                            _row('Total (Without Machine)', _totalWoM, bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading || _alreadySavedToday ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _alreadySavedToday
                                ? Colors.grey
                                : primaryIndigo,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            _alreadySavedToday
                                ? 'Already Saved Today'
                                : 'Save Daily Money',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(bold ? 1 : 0.85),
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 15 : 14,
            ),
          ),
          Text(
            'R ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryIndigo),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5),
      ),
      filled: true,
      fillColor: backgroundGrey,
    );
  }
}