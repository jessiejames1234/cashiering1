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

class _CashieringPageState extends State<CashieringPage>
    with SingleTickerProviderStateMixin {
  final Map<Product, int> _cart = {};
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  @override
  void initState() {
    super.initState();

    // Initialize product list and search listener
    _updateProductList();
    _searchController.addListener(_filterProducts);

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync:
          this, // Ensure the class uses 'with SingleTickerProviderStateMixin'
      lowerBound: 0.9,
      upperBound: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController
        .dispose(); // Dispose search controller to prevent memory leaks
    super.dispose();
  }

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

  final TextEditingController cashController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // ✅ Consistent rounded corners
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDEC6B1), // ✅ Background color to match `_showSaleDetails()`
            borderRadius: BorderRadius.circular(15),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              double totalAmount = _calculateTotal();
              double cash = double.tryParse(cashController.text) ?? 0.0;
              double change = cash - totalAmount;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Title
                  const Text(
                    "Payment",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Ordered Products List
                  const Text(
                    "Ordered Products",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Color(0xFFC29D7F)),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _cart.entries.map((entry) {
                      final product = entry.key;
                      final quantity = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC29D7F), // ✅ Consistent row color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "x$quantity",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                                                    SizedBox(width: 150),

                            Text(
                              "\₱${(product.price * quantity).toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const Divider(color: Color(0xFFC29D7F)),

                  // ✅ Total Amount Section
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC29D7F), // ✅ Matches `_showSaleDetails()`
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const TextSpan(
                            text: "Total Amount: ", // ✅ Label stays the same
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: "\₱${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: totalAmount > 0
                                  ? const Color.fromARGB(255, 26, 88, 29)
                                  : Colors.red, // ✅ Dynamic color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Cash Input Field
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Cash Amount",
                      prefixText: "\₱",
                      filled: true,
                      fillColor: Color(0xFFEFE6DD), // ✅ Light fill for input field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // ✅ Updates change calculation dynamically
                    },
                  ),

                  const SizedBox(height: 10),

                  // ✅ Change Amount (if applicable)
                  if (cash >= totalAmount)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Change: \₱${change.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),

                  if (cash < totalAmount && cashController.text.isNotEmpty)
                    const Text(
                      "Insufficient cash!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ✅ Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cash >= totalAmount ? Colors.green : Colors.grey,
                        ),
                        onPressed: cash >= totalAmount
                            ? () {
                                _recordSale();
                                Navigator.pop(context);
                              }
                            : null,
                        child: const Text("Pay"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}


  void _recordSale() {
    final salesBox = HiveBoxes.getSales();

    if (_cart.isEmpty) return;

    List<SaleItem> orderedProducts =
        _cart.entries.map((entry) {
          return SaleItem(
            name: entry.key.name,
            quantity: entry.value,
            price: entry.key.price,
          );
        }).toList();

    salesBox.add(
      Sale(
        products: orderedProducts,
        totalPrice: _calculateTotal(),
        date: DateTime.now(),
      ),
    );

    setState(() {
      _cart.clear(); // ✅ Clear cart after successful payment
    });

ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar() // ✅ Removes any existing SnackBar
  ..showSnackBar(
    SnackBar(
      content: Text(
        " added to cart!",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating, // ✅ Ensures it's above UI elements
      margin: const EdgeInsets.all(16), // ✅ Proper positioning
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // ✅ Modern rounded look
      ),
      duration: const Duration(seconds: 3), // ✅ Stays longer for better visibility
    ),
  );



  }

  /// ✅ Updates product list when Hive database changes
  void _updateProductList() {
    setState(() {
      _filteredProducts =
          HiveBoxes.getProducts().values
              .where((p) => p.isActive) // ✅ Only show active products
              .toList();
    });
  }

  /// ✅ Filters products based on search query
  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts =
          HiveBoxes.getProducts().values
              .where(
                (product) =>
                    product.isActive &&
                    product.name.toLowerCase().contains(query),
              )
              .toList();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEC6B1), // ✅ Matches the AppBar color

      appBar: AppBar(
        title: const Text(
          "Cashiering",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Material(
            color: Color.fromARGB(255, 168, 129, 97),
            elevation: 5,
            shadowColor: Colors.black, // ✅ Adds shadow effect (elevation)
            borderRadius: BorderRadius.circular(8), // ✅ Matches button shape
            child: TextButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 168, 129, 97),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                shadowColor: WidgetStateProperty.all(
                  Colors.black,
                ), // ✅ Shadow color
              ),
              onPressed: _showCart,
              icon: const Icon(Icons.shopping_cart, color: Colors.black),
              label: const Text("Cart", style: TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(width: 20),
        ],

        iconTheme: const IconThemeData(color: Colors.black),

        centerTitle: true,
        backgroundColor: const Color(0xFFC29D7F),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 10, // Adds a slight shadow for depth
        shadowColor: Colors.black,
        toolbarHeight: 80, // ✅ Increased height to add more bottom padding
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(50), // ✅ Increased bottom padding
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 10,
        shadowColor: Colors.black,
        child: Container(
          color: const Color(0xFFDEC6B1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Drawer Header with Logo
              DrawerHeader(
                child: SizedBox.expand(
                  // ✅ Ensures full width
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // ✅ Centers content
                    children: [
                      Image.asset(
                        "assets/images/b.png",
                        height: 120, // ✅ Adjust height as needed
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Menu Items
              Expanded(
                child: ListView(
                  children: [
                    Container(
                                            color: Color(0xFFC29D7F),

                      child: ListTile(
                        
                        leading: const Icon(
                          Icons.store,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        title: const Text(
                          "Manage Products",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageProductsPage(),
                            ),
                          ).then((_) => _updateProductList());
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      color: Color(0xFFC29D7F),
                      child: ListTile(
                        leading: const Icon(
                          Icons.bar_chart,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        title: const Text(
                          "Sales Monitoring",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SalesMonitoringPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Footer
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          children: [
            // Search Bar
            Card(
              color: Color(0xFFC29D7F),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4, // ✅ Adds a subtle shadow
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ), // ✅ Proper padding
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Search Product",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),

                    border:
                        InputBorder
                            .none, // ✅ Removes extra border (Fixes double box issue)
                  ),
                ),
              ),
            ),

            const Divider(color: Color(0xFFC29D7F)),

            // Product Grid
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: HiveBoxes.getProducts().listenable(),
                builder: (context, Box<Product> box, _) {
                  final allActiveProducts =
                      box.values.where((p) => p.isActive).toList();
                  final products =
                      _searchController.text.isEmpty
                          ? allActiveProducts
                          : allActiveProducts
                              .where(
                                (product) =>
                                    product.name.toLowerCase().contains(
                                      _searchController.text.toLowerCase(),
                                    ),
                              )
                              .toList();

                  if (allActiveProducts.isEmpty) {
                    return const Center(
                      child: Text("No active products available."),
                    );
                  } else if (products.isEmpty) {
                    return const Center(child: Text("No products found."));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // More space for modern UI
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
return Builder(
  builder: (BuildContext rootContext) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
        });
        _addToCart(product);

        // ✅ Correctly shows SnackBar
        ScaffoldMessenger.of(rootContext)
          ..hideCurrentSnackBar() // ✅ Removes previous SnackBar
          ..showSnackBar(
            SnackBar(
              content: Text(
                "${product.name} added to cart!",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating, // ✅ Ensures visibility
              margin: const EdgeInsets.all(16), // ✅ Adds spacing
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // ✅ Modern rounded design
              ),
              duration: const Duration(seconds: 3), // ✅ Stays longer
            ),
          );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          color: const Color(0xFFC29D7F),
          elevation: 10,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _displayProductImage(product),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    const SizedBox(height: 4),
                    Text(
                      "\₱${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 26, 88, 29),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  },
);
                    },
                  );
                },
              ),
            ),

            
          ],

        ),
      ),




      

    );


  }

  void _showCart() {
    // ✅ Remove inactive products from the cart before displaying
    _cart.removeWhere((product, _) => !product.isActive);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final ScrollController scrollController = ScrollController();

            return Container(
              color: Color(0xFFDEC6B1),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  height: 500, // ✅ Adjusted height
                  child: Column(
                    children: [
                      // ✅ Top Drag Handle
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 168, 129, 97),

                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ✅ Title
                      const Text(
                        "All Order",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                        color: Color.fromARGB(255, 168, 129, 97),
                      ),

                      Expanded(
                        child:
                            _cart.isEmpty
                                ? const Center(
                                  child: Text(
                                    "Your cart is empty.",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final product = _cart.keys.elementAt(index);
                                    final int quantity = _cart[product]!;
                                    final double totalPrice =
                                        product.price * quantity;
                                    final TextEditingController
                                    quantityController = TextEditingController(
                                      text: quantity.toString(),
                                    );

                                    return Card(
                                      color: Color(0xFFC29D7F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: _displayProductImageONE(
                                                product,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // ✅ Product Name and Price
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    "\₱${product.price.toStringAsFixed(2)} each",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color.fromARGB(
                                                        255,
                                                        26,
                                                        88,
                                                        29,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    "Total: \₱${totalPrice.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // ✅ Quantity Controls
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _removeFromCart(product);
                                                    });
                                                  },
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: TextField(
                                                    controller:
                                                        quantityController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration:
                                                        const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                    onChanged: (value) {
                                                      int newQuantity =
                                                          int.tryParse(value) ??
                                                          0;
                                                      if (newQuantity > 0) {
                                                        setState(() {
                                                          _cart[product] =
                                                              newQuantity;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add,
                                                    color: Color.fromARGB(
                                                      255,
                                                      0,
                                                      0,
                                                      0,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _addToCart(product);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),

                                            // ✅ "X" Button to Remove Product from Cart
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cart.remove(
                                                    product,
                                                  ); // ✅ Remove the product
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),

                      const Divider(color: Color(0xFFC29D7F)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Total Amount: \₱${_calculateTotal().toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // ✅ Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed:
                                _cart.isNotEmpty
                                    ? () {
                                      setState(() {
                                        _cart.clear();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Cart cleared successfully.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      });
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            label: const Text("Clear Cart"),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.payment,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _checkout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            label: const Text("Checkout"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
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
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(10), // ✅ Rounded top corners
          ),
          border: Border(
            top: BorderSide(
              color: Color(0xFFC29D7F), // ✅ Top border color
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Image.network(
            product.imagePath,
            width: 140,
            height: 55,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (!kIsWeb && product.imagePath.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(top: BorderSide(            color: Color(0xFFC29D7F), width: 3)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Image.file(
            File(product.imagePath),

            width: 120,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
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
