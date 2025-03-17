import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0)
  final List<SaleItem> products; // ✅ Store multiple products

  @HiveField(1)
  final double totalPrice;

  @HiveField(2)
  final DateTime date;

  Sale({required this.products, required this.totalPrice, required this.date});
}

@HiveType(typeId: 2)
class SaleItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double price;

  SaleItem({required this.name, required this.quantity, required this.price});
}
