import 'package:cloud_firestore/cloud_firestore.dart';

class DailyMoney {
  final String id;
  final String userId;
  final DateTime date;
  final double notesTotal;
  final double coinsTotal;
  final double machineAmount;
  final double totalWithMachine;
  final double totalWithoutMachine;
  final DateTime timestamp;
  final bool isFinalized; // If true, cannot be edited

  DailyMoney({
    required this.id,
    required this.userId,
    required this.date,
    required this.notesTotal,
    required this.coinsTotal,
    required this.machineAmount,
    required this.totalWithMachine,
    required this.totalWithoutMachine,
    required this.timestamp,
    this.isFinalized = false,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'notesTotal': notesTotal,
    'coinsTotal': coinsTotal,
    'machineAmount': machineAmount,
    'totalWithMachine': totalWithMachine,
    'totalWithoutMachine': totalWithoutMachine,
    'timestamp': Timestamp.fromDate(timestamp),
    'isFinalized': isFinalized,
  };

  factory DailyMoney.fromMap(String id, Map<String, dynamic> map) => DailyMoney(
    id: id,
    userId: map['userId'] ?? '',
    date: (map['date'] as Timestamp).toDate(),
    notesTotal: (map['notesTotal'] ?? 0.0).toDouble(),
    coinsTotal: (map['coinsTotal'] ?? 0.0).toDouble(),
    machineAmount: (map['machineAmount'] ?? 0.0).toDouble(),
    totalWithMachine: (map['totalWithMachine'] ?? 0.0).toDouble(),
    totalWithoutMachine: (map['totalWithoutMachine'] ?? 0.0).toDouble(),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    isFinalized: map['isFinalized'] ?? false,
  );
}