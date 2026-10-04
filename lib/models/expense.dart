import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final String itemName;
  final double price;
  final DateTime date;
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.price,
    required this.date,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'itemName': itemName,
    'price': price,
    'date': Timestamp.fromDate(date),
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
    id: id,
    userId: map['userId'] ?? '',
    itemName: map['itemName'] ?? '',
    price: (map['price'] ?? 0.0).toDouble(),
    date: (map['date'] as Timestamp).toDate(),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
  );
}