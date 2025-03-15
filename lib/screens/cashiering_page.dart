import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../db/hive_boxes.dart';
import 'manage_products_page.dart';
import 'sales_monitoring_page.dart';

class CashieringPage extends StatefulWidget {
  const CashieringPage({super.key});

  @override
  State<CashieringPage> createState() => _CashieringPageState();
}

class _CashieringPageState extends State<CashieringPage> {
  final Map<Product, int> _cart = {};

  void _addToCart(Product product) {
    setState(() {
      _cart.update(
        product,
        (existingQty) => existingQty + 1,
        ifAbsent: () => 1,
      );
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product)) {
        if (_cart[product]! > 1) {
          _cart[product] = _cart[product]! - 1;
        } else {
          _cart.remove(product);
        }
      }
    });
  }

  double _calculateTotal() {
    return _cart.entries.fold(0, (total, entry) {
      return total + (entry.key.price * entry.value);
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Payment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total Amount: \$${_calculateTotal().toStringAsFixed(2)}"),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  _recordSale();
                  Navigator.pop(context);
                },
                child: const Text("Pay"),
              ),
            ],
          ),
    );
  }

  void _recordSale() {
    final salesBox = HiveBoxes.getSales();
    for (var entry in _cart.entries) {
      salesBox.add(
        Sale(
          productName: entry.key.name,
          totalPrice: entry.key.price * entry.value,
          quantity: entry.value,
          date: DateTime.now(),
        ),
      );
    }

    setState(() {
      _cart.clear(); // ✅ Clear cart after successful payment
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Successful! Sale recorded."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cashiering"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _showCart,
          ),
          IconButton(
            icon: const Icon(Icons.store),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProductsPage(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesMonitoringPage(),
                  ),
                ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveBoxes.getProducts().listenable(),
        builder: (context, Box<Product> box, _) {
          final products = box.values.where((p) => p.isActive).toList();
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: _displayProductImage(product), // ✅ Added Image Display
                title: Text(product.name),
                subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () => _addToCart(product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // ✅ Allows real-time UI updates inside the cart
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 400,
              child: Column(
                children: [
                  const Text(
                    "Cart",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _cart.isEmpty
                            ? const Center(child: Text("No items in cart"))
                            : ListView.builder(
                              itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final product = _cart.keys.elementAt(index);
                                final quantity = _cart[product]!;

                                return ListTile(
                                  leading: _displayProductImage(
                                    product,
                                  ), // ✅ Added Image Display
                                  title: Text(product.name),
                                  subtitle: Text("Qty: $quantity"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          setState(() {
                                            _removeFromCart(
                                              product,
                                            ); // ✅ Updates cart UI
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            _addToCart(
                                              product,
                                            ); // ✅ Updates cart UI
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  const Divider(),
                  Text(
                    "Total: \$${_calculateTotal().toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close Cart First
                      _checkout(); // ✅ Proceed to checkout
                    },
                    child: const Text("Proceed to Payment"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ **Displays Product Image for Web & Mobile**
  Widget _displayProductImage(Product product) {
    if (kIsWeb && product.imagePath.startsWith("data:image")) {
      return Image.network(
        product.imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && product.imagePath.isNotEmpty) {
      return Image.file(
        File(product.imagePath),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.image, size: 50);
  }
}
