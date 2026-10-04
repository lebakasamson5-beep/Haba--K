import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '/app_theme.dart';

class MoneyUsedScreen extends StatefulWidget {
  const MoneyUsedScreen({super.key});

  @override
  State<MoneyUsedScreen> createState() => _MoneyUsedScreenState();
}

class _MoneyUsedScreenState extends State<MoneyUsedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _item = TextEditingController();
  final _price = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final now = DateTime.now();

      await db.saveExpense(Expense(
        id: '',
        userId: auth.currentUser!.email,
        itemName: _item.text.trim(),
        price: double.parse(_price.text),
        date: now,
        timestamp: now,
      ));

      Fluttertoast.showToast(
        msg: '✅ Expense saved',
        backgroundColor: AppTheme.income,
        textColor: Colors.white,
      );
      _item.clear();
      _price.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: '❌ Error: $e',
        backgroundColor: AppTheme.expense,
        textColor: Colors.white,
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppTheme.appBar('Money Used'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppTheme.responsive(
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryIndigo, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                            style: const TextStyle(color: AppTheme.deepIndigo, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _item,
                    decoration: _inputDecoration('Item Name', Icons.shopping_bag_outlined),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _price,
                    decoration: _inputDecoration('Price (R)', Icons.attach_money_rounded),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return double.tryParse(v) == null ? 'Invalid number' : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryIndigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Expenses are deducted from the previous day's remaining money",
                            style: TextStyle(color: Color(0xFF8A6D00), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryIndigo),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryIndigo, width: 1.5),
      ),
      filled: true,
      fillColor: AppTheme.backgroundGrey,
    );
  }

  @override
  void dispose() {
    _item.dispose();
    _price.dispose();
    super.dispose();
  }
}