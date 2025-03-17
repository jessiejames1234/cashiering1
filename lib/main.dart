import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/product.dart';
import 'models/sale.dart';
import 'screens/cashiering_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(SaleAdapter()); 
  Hive.registerAdapter(SaleItemAdapter()); // ✅ Register SaleItem adapter
  Hive.registerAdapter(ProductAdapter()); // ✅ Register Product adapter if needed

  await Hive.openBox<Sale>('sales');  // ✅ Ensure the "sales" box is opened
  await Hive.openBox<Product>('products');  // ✅ Ensure the "products" box is opened

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CashieringPage(),
    );
  }
}
