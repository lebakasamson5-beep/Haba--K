class Product {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final int quantity;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'name': name,
    'price': price,
    'quantity': quantity,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
    id: id,
    barcode: map['barcode'] ?? '',
    name: map['name'] ?? '',
    price: (map['price'] ?? 0.0).toDouble(),
    quantity: map['quantity'] ?? 0,
    category: map['category'] ?? 'Uncategorized',
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: DateTime.parse(map['updatedAt']),
  );
}