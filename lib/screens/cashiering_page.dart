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
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];


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

  final TextEditingController _cashController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder( // ✅ Allows updating the dialog UI dynamically
        builder: (context, setState) {
          double totalAmount = _calculateTotal();
          double cash = double.tryParse(_cashController.text) ?? 0.0;
          double change = cash - totalAmount;

          return AlertDialog(
            title: const Text("Payment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ordered Products:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _cart.entries.map((entry) {
                    final product = entry.key;
                    final quantity = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(product.name)), // Product Name
                          Text("x$quantity"), // Quantity
                          Text("\$${(product.price * quantity).toStringAsFixed(2)}"), // Total Price per Product
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Divider(),
                Text(
                  "Total Amount: \$${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // ✅ Cash Input Field
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter Cash Amount",
                    prefixText: "\$",
                  ),
                  onChanged: (value) {
                    setState(() {}); // ✅ Updates change calculation dynamically
                  },
                ),

                const SizedBox(height: 10),
                // ✅ Show Change Amount (if cash entered is sufficient)
                if (cash >= totalAmount)
                  Text(
                    "Change: \$${change.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),

                if (cash < totalAmount && _cashController.text.isNotEmpty)
                  const Text(
                    "Insufficient cash!",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: cash >= totalAmount
                    ? () {
                        _recordSale();
                        Navigator.pop(context);
                      }
                    : null, // ✅ Disable button if cash is insufficient
                child: const Text("Pay"),
              ),
            ],
          );
        },
      );
    },
  );
}


void _recordSale() {
  final salesBox = HiveBoxes.getSales();

  if (_cart.isEmpty) return;

  List<SaleItem> orderedProducts = _cart.entries.map((entry) {
    return SaleItem(
      name: entry.key.name,
      quantity: entry.value,
      price: entry.key.price,
    );
  }).toList();

  salesBox.add(Sale(
    products: orderedProducts,
    totalPrice: _calculateTotal(),
    date: DateTime.now(),
  ));

  setState(() {
    _cart.clear(); // ✅ Clear cart after successful payment
  });

  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text("Payment Successful! Sale recorded."),
    backgroundColor: Colors.green,
  ));
}


  @override
  void initState() {
    super.initState();
    _updateProductList();
    _searchController.addListener(_filterProducts);
  }

  /// ✅ Updates product list when Hive database changes
  void _updateProductList() {
    setState(() {
      _filteredProducts = HiveBoxes.getProducts()
          .values
          .where((p) => p.isActive) // ✅ Only show active products
          .toList();
    });
  }

  /// ✅ Filters products based on search query
  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = HiveBoxes.getProducts()
          .values
          .where((product) => product.isActive && product.name.toLowerCase().contains(query))
          .toList();
    });
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageProductsPage()),
          ).then((_) => _updateProductList()), // ✅ Refresh list after returning
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesMonitoringPage()),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        // ✅ Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: "Search Product",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: HiveBoxes.getProducts().listenable(),
            builder: (context, Box<Product> box, _) {
              // ✅ Get active products
              final allActiveProducts = box.values.where((p) => p.isActive).toList();

              // ✅ Apply search filter
              final products = _searchController.text.isEmpty
                  ? allActiveProducts
                  : allActiveProducts
                      .where((product) =>
                          product.name.toLowerCase().contains(_searchController.text.toLowerCase()))
                      .toList();

              if (allActiveProducts.isEmpty) {
                return const Center(child: Text("No active products available."));
              } else if (products.isEmpty) {
                return const Center(child: Text("No products found."));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // ✅ Display 3 per row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.75, // ✅ Adjust card height
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () => _addToCart(product), // ✅ Clickable to add to cart
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _displayProductImage(product),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  "\$${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}





void _showCart() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ Allows full view on smaller screens
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 450,
            child: Column(
              children: [
                const Text(
                  "Cart",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text("No items in cart"))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final product = _cart.keys.elementAt(index);
                            final TextEditingController quantityController =
                                TextEditingController(text: _cart[product]!.toString());

                            return ListTile(
                              leading: _displayProductImageONE(product), // ✅ Shows Product Image
                              title: Text(product.name),
                              subtitle: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        _removeFromCart(product);
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) { // ✅ Updates instantly when typing
                                        int newQuantity = int.tryParse(value) ?? 0;
                                        if (newQuantity > 0) {
                                          setState(() {
                                            _cart[product] = newQuantity;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        _addToCart(product);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red), // ✅ "X" to remove item
                                onPressed: () {
                                  setState(() {
                                    _cart.remove(product); // ✅ Remove the product completely
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                Text(
                  "Total: \$${_calculateTotal().toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _cart.isNotEmpty
                          ? () {
                              setState(() {
                                _cart.clear(); // ✅ Clears entire cart
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Clear All"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Cart First
                        _checkout(); // ✅ Proceed to checkout
                      },
                      child: const Text("Proceed to Payment"),
                    ),
                  ],
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
        width: 120,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && product.imagePath.isNotEmpty) {
      return Image.file(
        File(product.imagePath),
        width: 120,
        height: 50,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.image, size: 50);
  }

    Widget _displayProductImageONE(Product product) {
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
