import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/sale.dart';

class HiveBoxes {
  static Box<Product> getProducts() => Hive.box<Product>('products');
  static Box<Sale> getSales() => Hive.box<Sale>('sales');
}
