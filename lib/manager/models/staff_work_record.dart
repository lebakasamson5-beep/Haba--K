class StaffWorkRecord {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime date;
  final double dailyMoney;
  final double expenses;
  final double netProfit;

  StaffWorkRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.dailyMoney,
    required this.expenses,
    required this.netProfit,
  });

  Map<String, dynamic> toMap() => {
    'staffId': staffId,
    'staffName': staffName,
    'date': date.toIso8601String(),
    'dailyMoney': dailyMoney,
    'expenses': expenses,
    'netProfit': netProfit,
  };

  factory StaffWorkRecord.fromMap(String id, Map<String, dynamic> map) => StaffWorkRecord(
    id: id,
    staffId: map['staffId'] ?? '',
    staffName: map['staffName'] ?? '',
    date: DateTime.parse(map['date']),
    dailyMoney: (map['dailyMoney'] ?? 0.0).toDouble(),
    expenses: (map['expenses'] ?? 0.0).toDouble(),
    netProfit: (map['netProfit'] ?? 0.0).toDouble(),
  );
}