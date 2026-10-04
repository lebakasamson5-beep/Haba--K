import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../services/staff_approval_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  final StaffApprovalService _approvalService = StaffApprovalService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<UserModel> _staffList = [];
  List<UserModel> _filteredList = [];
  int _approvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _approvalService.autoDeleteUnapprovedStaff();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _staffList = await _approvalService.getAllStaff();
      _approvedCount = await _approvalService.getApprovedStaffCount();
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Could not load staff. Pull down to try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredList = query.isEmpty
          ? List.of(_staffList)
          : _staffList.where((s) {
        return s.fullName.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _toggleApproval(UserModel staff) async {
    if (staff.isApproved) {
      await _approvalService.rejectStaff(staff.uid);
      Fluttertoast.showToast(
        msg: '${staff.fullName} unapproved',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    } else {
      final canApprove = await _approvalService.approveStaff(staff.uid);
      if (canApprove) {
        Fluttertoast.showToast(
          msg: '✅ ${staff.fullName} approved!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: '❌ Staff limit reached (${StaffApprovalService.MAX_APPROVED_STAFF})',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
    await _loadData();
  }

  Future<void> _toggleLock(UserModel staff) async {
    if (staff.isLocked) {
      await _approvalService.unlockStaff(staff.uid);
      Fluttertoast.showToast(
        msg: '🔓 ${staff.fullName} unlocked',
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } else {
      await _approvalService.lockStaff(staff.uid);
      Fluttertoast.showToast(
        msg: '🔒 ${staff.fullName} locked',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
    await _loadData();
  }

  Future<void> _showWeekPicker(UserModel staff) async {
    final currentWeek = staff.assignedWeek ?? 0;

    final selected = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WeekPickerDialog(
        staff: staff,
        currentWeek: currentWeek,
      ),
    );

    if (selected != null && selected != currentWeek) {
      await _approvalService.assignWorkingWeek(staff.uid, selected);
      Fluttertoast.showToast(
        msg: '${staff.fullName} assigned to Week $selected',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _loadData();
    }
  }

  Future<void> _deleteStaff(UserModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Staff Account'),
        content: Text(
          'This permanently removes ${staff.fullName} and cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final success = await auth.deleteStaffAccount(staff.uid);
        Fluttertoast.showToast(
          msg: success ? '🗑️ ${staff.fullName} deleted' : 'Failed to delete staff',
          backgroundColor: success ? Colors.red : Colors.orange,
          textColor: Colors.white,
        );
        if (success) await _loadData();
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _approvedCount >= StaffApprovalService.MAX_APPROVED_STAFF;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Manage Staff'),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF3949AB),
        child: Column(
          children: [
            _buildLimitBanner(atLimit),
            _buildSearchBar(),
            Expanded(child: _buildStaffList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitBanner(bool atLimit) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: atLimit ? Colors.red.withOpacity(0.08) : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, color: atLimit ? Colors.red : Colors.grey),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Approved Staff Limit', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(
            '$_approvedCount / ${StaffApprovalService.MAX_APPROVED_STAFF}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: atLimit ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search staff by name or email',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList() {
    if (_filteredList.isEmpty) {
      final noStaffAtAll = _staffList.isEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noStaffAtAll ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              noStaffAtAll ? 'No staff members registered yet' : 'No staff match your search',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (noStaffAtAll) ...[
              const SizedBox(height: 8),
              Text(
                'Staff will appear here when they register',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) => _buildStaffCard(_filteredList[index]),
    );
  }

  Widget _buildStaffCard(UserModel staff) {
    final isApproved = staff.isApproved;
    final isLocked = staff.isLocked;
    final daysOld = DateTime.now().difference(staff.createdAt).inDays;
    final daysLeft = 10 - daysOld;
    final assignedWeek = staff.assignedWeek;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isApproved
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  child: Text(
                    staff.firstName.isNotEmpty ? staff.firstName[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: isApproved ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        staff.email,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _statusChip(
                            isApproved ? '✅ Approved' : '⏳ Pending',
                            isApproved ? Colors.green : Colors.orange,
                          ),
                          _statusChip(
                            isLocked ? '🔒 Locked' : '🔓 Unlocked',
                            isLocked ? Colors.red : Colors.green,
                          ),
                          if (assignedWeek != null && assignedWeek > 0)
                            _statusChip(
                              '📅 Week $assignedWeek',
                              const Color(0xFF3949AB),
                            ),
                          if (!isApproved)
                            _statusChip(
                              daysLeft > 0 ? '$daysLeft days left' : 'Expiring today',
                              Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleApproval(staff),
                    icon: Icon(
                      isApproved ? Icons.check_circle : Icons.pending_actions,
                      size: 18,
                      color: isApproved ? Colors.green : Colors.orange,
                    ),
                    label: Text(
                      isApproved ? 'Unapprove' : 'Approve',
                      style: TextStyle(color: isApproved ? Colors.green : Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isApproved ? Colors.green : Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Assign working week',
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF3949AB)),
                    onPressed: () => _showWeekPicker(staff),
                  ),
                ),
                Tooltip(
                  message: isLocked ? 'Unlock staff' : 'Lock staff',
                  child: IconButton(
                    icon: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _toggleLock(staff),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                  onSelected: (value) {
                    if (value == 'delete') _deleteStaff(staff);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete staff'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================
// Week Picker Dialog with Calendar View
// ============================================================
class WeekPickerDialog extends StatefulWidget {
  final UserModel staff;
  final int currentWeek;

  const WeekPickerDialog({
    super.key,
    required this.staff,
    required this.currentWeek,
  });

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  int? _selectedWeek;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.currentWeek > 0 ? widget.currentWeek : null;
  }

  // Get the date range for a given week number in the current month
  String _getWeekDateRange(int weekNumber) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate the start day of the week
    final startDay = (weekNumber - 1) * 7 + 1;
    final endDay = (weekNumber * 7).clamp(1, _getDaysInMonth(now.year, now.month));

    final startDate = DateTime(now.year, now.month, startDay);
    final endDate = DateTime(now.year, now.month, endDay);

    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get the days of the week for a given week number
  List<DateTime> _getDaysInWeek(int weekNumber) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final startDay = (weekNumber - 1) * 7 + 1;
    final endDay = (weekNumber * 7).clamp(1, _getDaysInMonth(now.year, now.month));

    final days = <DateTime>[];
    for (int day = startDay; day <= endDay; day++) {
      days.add(DateTime(now.year, now.month, day));
    }
    return days;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Color(0xFF3949AB), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Working Week',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        'Select a week for ${widget.staff.fullName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Week Selection Cards
            ...List.generate(4, (index) {
              final weekNumber = index + 1;
              final isSelected = _selectedWeek == weekNumber;
              final days = _getDaysInWeek(weekNumber);
              final dateRange = _getWeekDateRange(weekNumber);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedWeek == weekNumber) {
                      _selectedWeek = null;
                    } else {
                      _selectedWeek = weekNumber;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3949AB).withOpacity(0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3949AB)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Week Number
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3949AB)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'W$weekNumber',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Week Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week $weekNumber',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isSelected
                                    ? const Color(0xFF3949AB)
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateRange,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Day indicators
                            Row(
                              children: days.map((day) {
                                final isToday = _isToday(day);
                                return Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_getDayName(day.weekday)} ${day.day}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isToday ? Colors.green.shade700 : Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Selection indicator
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF3949AB),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedWeek ?? 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3949AB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _selectedWeek != null
                          ? 'Assign Week $_selectedWeek'
                          : 'Clear Week',
                    ),
                  ),
                ),
              ],
            ),

            // Info note
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff can only access the system during their assigned week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}