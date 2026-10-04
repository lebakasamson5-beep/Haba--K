import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/manager_service.dart';
import '../../services/auth_service.dart';
import '/app_theme.dart'; // adjust path to match your project

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final ManagerService _managerService = ManagerService();
  bool _isLoading = true;
  Map<String, dynamic> _todayData = {};
  List<Map<String, dynamic>> _weeklyComparison = [];
  List<Map<String, dynamic>> _staffPerformance = [];
  String _selectedPeriod = 'Daily';
  DateTime _selectedDate = DateTime.now();
  double _totalMoneyAllTime = 0;
  double _totalExpensesAllTime = 0;
  int _totalStaff = 0;

  final DateFormat _dateFormat = DateFormat('MMM d, y');

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      _todayData = await _managerService.getDailyPerformance(_selectedDate);
      final startOfWeek = _getStartOfWeek(_selectedDate);
      await _managerService.getWeeklyPerformance(startOfWeek);
      await _managerService.getMonthlyPerformance(_selectedDate.year, _selectedDate.month);
      _weeklyComparison = await _managerService.getWeeklyComparison();
      _staffPerformance = await _managerService.getStaffPerformanceSummary();
      _totalMoneyAllTime = await _managerService.getTotalMoneyAllTime();
      _totalExpensesAllTime = await _managerService.getTotalExpensesAllTime();
      _totalStaff = await _managerService.getAllStaff().then((list) => list.length);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthService>(context);
    final netProfit = _totalMoneyAllTime - _totalExpensesAllTime;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo))
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primaryIndigo,
        child: AppTheme.responsive(
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(netProfit),
                const SizedBox(height: 16),
                _buildDateNavigation(),
                const SizedBox(height: 16),
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                _buildTodaySummary(),
                const SizedBox(height: 16),
                _buildWeeklyChart(),
                const SizedBox(height: 16),
                _buildStaffPerformance(),
                const SizedBox(height: 16),
                _buildWeeklyComparisonList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double netProfit) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('Total Revenue', AppTheme.currency(_totalMoneyAllTime), AppTheme.income, Icons.trending_up),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard('Total Expenses', AppTheme.currency(_totalExpensesAllTime), AppTheme.expense, Icons.shopping_cart),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Profit',
                AppTheme.currency(netProfit),
                netProfit >= 0 ? AppTheme.primaryIndigo : AppTheme.expense,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard('Staff', _totalStaff.toString(), AppTheme.neutral, Icons.people),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: AppTheme.primaryIndigo), onPressed: () => _changeDate(-1)),
          Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          IconButton(icon: const Icon(Icons.chevron_right, color: AppTheme.primaryIndigo), onPressed: () => _changeDate(1)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['Daily', 'Weekly', 'Monthly'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedPeriod = period),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppTheme.deepIndigo : Colors.white,
                foregroundColor: isSelected ? Colors.white : AppTheme.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppTheme.deepIndigo : Colors.grey.shade300),
                ),
              ),
              child: Text(period),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodaySummary() {
    final userMoney = (_todayData['userMoney'] as Map?)?.cast<String, double>() ?? {};
    final userNames = (_todayData['userNames'] as Map?)?.cast<String, String>() ?? {};

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Revenue', AppTheme.currency((_todayData['totalMoney'] ?? 0.0)), AppTheme.income)),
              Expanded(child: _buildSummaryItem('Expenses', AppTheme.currency((_todayData['totalExpenses'] ?? 0.0)), AppTheme.expense)),
              Expanded(
                child: _buildSummaryItem(
                  'Net Profit',
                  AppTheme.currency((_todayData['netProfit'] ?? 0.0)),
                  (_todayData['netProfit'] ?? 0.0) >= 0 ? AppTheme.primaryIndigo : AppTheme.expense,
                ),
              ),
            ],
          ),
          if (userMoney.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryIndigo.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff working today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...userMoney.entries.map((entry) {
                    final userName = userNames[entry.key] ?? entry.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(userName),
                          Text(AppTheme.currency(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  /// Lightweight bar chart, built with plain widgets — no chart package
  /// dependency required. Shows net profit per week so trends are easy
  /// to spot at a glance.
  Widget _buildWeeklyChart() {
    if (_weeklyComparison.isEmpty) return const SizedBox.shrink();

    final profits = _weeklyComparison.map((w) => ((w['netProfit'] ?? 0.0) as num).toDouble()).toList();
    final maxAbs = profits.map((p) => p.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxAbs == 0 ? 1.0 : maxAbs;
    const chartHeight = 140.0;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: AppTheme.primaryIndigo, size: 20),
              SizedBox(width: 8),
              Text('Weekly Profit Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyComparison.asMap().entries.map((entry) {
                final week = entry.value;
                final profit = ((week['netProfit'] ?? 0.0) as num).toDouble();
                final isLoss = profit < 0;
                final barHeight = (profit.abs() / safeMax) * (chartHeight - 36);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppTheme.currency(profit),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isLoss ? AppTheme.expense : AppTheme.income,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: barHeight.clamp(4.0, chartHeight - 36),
                          decoration: BoxDecoration(
                            color: isLoss ? AppTheme.expense : AppTheme.primaryIndigo,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'W${week['weekNumber']}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPerformance() {
    if (_staffPerformance.isEmpty) {
      return Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(20),
        child: const Center(child: Text('No staff performance data available', style: TextStyle(color: AppTheme.textGrey))),
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._staffPerformance.map((staff) {
            final user = staff['user'];
            final profit = ((staff['netProfit'] ?? 0.0) as num).toDouble();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppTheme.currency(profit),
                        style: TextStyle(fontWeight: FontWeight.bold, color: profit >= 0 ? AppTheme.income : AppTheme.expense),
                      ),
                      Text('${staff['transactionCount'] ?? 0} transactions', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyComparisonList() {
    if (_weeklyComparison.isEmpty) return const SizedBox.shrink();

    final allProfits = _weeklyComparison.map((w) => ((w['netProfit'] ?? 0.0) as num).toDouble()).toList();
    final highest = allProfits.reduce((a, b) => a > b ? a : b);
    final lowest = allProfits.reduce((a, b) => a < b ? a : b);
    final highestWeek = _weeklyComparison.firstWhere((w) => ((w['netProfit'] ?? 0.0) as num).toDouble() == highest);
    final lowestWeek = _weeklyComparison.firstWhere((w) => ((w['netProfit'] ?? 0.0) as num).toDouble() == lowest);

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Performance Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildWeekCard('Highest Week', highestWeek, AppTheme.income, Icons.emoji_events)),
              const SizedBox(width: 8),
              Expanded(child: _buildWeekCard('Lowest Week', lowestWeek, AppTheme.expense, Icons.trending_down)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('All Weeks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._weeklyComparison.map((week) => _buildWeekListItem(week, highest, lowest)),
        ],
      ),
    );
  }

  Widget _buildWeekCard(String title, Map<String, dynamic> week, Color color, IconData icon) {
    final profit = ((week['netProfit'] ?? 0.0) as num).toDouble();
    final staffName = week['staffName'] ?? 'No staff';
    final staffCount = week['staffCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Week ${week['weekNumber']}', style: const TextStyle(fontSize: 12)),
          FittedBox(
            child: Text(AppTheme.currency(profit), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
          Text('$staffCount staff', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
          if (staffName != 'No staff')
            Text('Top: $staffName', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWeekListItem(Map<String, dynamic> week, double highest, double lowest) {
    final profit = ((week['netProfit'] ?? 0.0) as num).toDouble();
    final staffName = week['staffName'] ?? 'No staff';
    final staffCount = week['staffCount'] ?? 0;
    final isHighest = profit == highest;
    final isLowest = profit == lowest;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighest ? AppTheme.income.withOpacity(0.06) : (isLowest ? AppTheme.expense.withOpacity(0.06) : AppTheme.backgroundGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ${week['weekNumber']}: ${_dateFormat.format(week['startDate'])} - ${_dateFormat.format(week['endDate'])}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text('$staffCount staff · Top: $staffName', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Text(
            AppTheme.currency(profit),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighest ? AppTheme.income : (isLowest ? AppTheme.expense : AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}