import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0)
  String productName;

  @HiveField(1)
  double totalPrice;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  DateTime date;

  Sale({
    required this.productName,
    required this.totalPrice,
    required this.quantity,
    required this.date,
  });
}
