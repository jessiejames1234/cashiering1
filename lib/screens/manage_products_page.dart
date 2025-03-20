import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../db/hive_boxes.dart';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // ✅ Search input

  String? _selectedImagePath;
  Uint8List? _webImageBytes;
  List<Product> _filteredProducts = [];

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // 🌐 Web: Pick image and store as Base64
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.bytes != null) {
        _webImageBytes = result.files.single.bytes;
        _selectedImagePath =
            "data:image/png;base64,${base64Encode(_webImageBytes!)}";
      }
    } else {
      // 📱 Mobile: Pick image and store file path
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        _selectedImagePath = pickedFile.path;
        _webImageBytes = null;
      }
    }
  }

  void _addProduct() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;

    // ✅ Check if the product name already exists
    bool nameExists = HiveBoxes.getProducts().values.any(
      (product) => product.name.toLowerCase() == name.toLowerCase(),
    );

    if (nameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product '$name' already exists!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (name.isNotEmpty &&
        price > 0 &&
        (_selectedImagePath != null || _webImageBytes != null)) {
      final product = Product(
        name: name,
        price: price,
        imagePath:
            kIsWeb && _webImageBytes != null
                ? "data:image/png;base64,${base64Encode(_webImageBytes!)}"
                : _selectedImagePath!,
      );

      HiveBoxes.getProducts().add(product);

      _nameController.clear();
      _priceController.clear();
      setState(() {
        _selectedImagePath = null;
        _webImageBytes = null;
      });

      // ✅ Show success message with product name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product '$name' added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

void _editProduct(Product product) {
  _nameController.text = product.name;
  _priceController.text = product.price.toString();

  if (kIsWeb && product.imagePath.startsWith("data:image")) {
    _webImageBytes = base64Decode(product.imagePath.split(",")[1]);
    _selectedImagePath = product.imagePath;
  } else {
    _selectedImagePath = product.imagePath;
    _webImageBytes = null;
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // ✅ Rounded corners
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDEC6B1), // ✅ Consistent background color
            borderRadius: BorderRadius.circular(15),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Title
                  const Text(
                    "Edit Product",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Product Name Input
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Product Name",
                      filled: true,
                      fillColor: Color(0xFFEFE6DD), // ✅ Light fill color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Price Input
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      prefixText: "₱",
                      filled: true,
                      fillColor: Color(0xFFEFE6DD), // ✅ Light fill color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Image Preview
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC29D7F), // ✅ Matches other modals
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImagePath != null || _webImageBytes != null
                        ? _displayImage()
                        : const Icon(Icons.image, size: 100, color: Colors.white),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Change Image Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // ✅ Color matches the theme
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _pickImage();
                      setState(() {});
                    },
                    icon: const Icon(Icons.image),
                    label: const Text("Change Image"),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Buttons (Cancel & Save)
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
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          final newName = _nameController.text.trim();
                          final newPrice =
                              double.tryParse(_priceController.text) ?? product.price;

                          // ✅ Ensure new name is unique (excluding the same product)
                          bool nameExists = HiveBoxes.getProducts().values.any(
                            (p) =>
                                p.name.toLowerCase() == newName.toLowerCase() &&
                                p.key != product.key,
                          );

                          if (nameExists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Product '$newName' already exists!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          product.name = newName;
                          product.price = newPrice;

                          if (_selectedImagePath != null || _webImageBytes != null) {
                            product.imagePath =
                                kIsWeb && _webImageBytes != null
                                    ? "data:image/png;base64,${base64Encode(_webImageBytes!)}"
                                    : _selectedImagePath!;
                          }

                          product.save();
                          Navigator.pop(context);
                          setState(() {});

                          // ✅ Show success message with product name
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Product '$newName' updated successfully!",
                              ),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        child: const Text("Save Changes"),
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


  void _toggleActive(Product product) {
    product.isActive = !product.isActive;
    product.save();

    // ✅ Show success message with product name
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          product.isActive
              ? "Product '${product.name}' activated successfully!"
              : "Product '${product.name}' deactivated successfully!",
        ),
        backgroundColor: product.isActive ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _displayImage() {
    if (_selectedImagePath == null && _webImageBytes == null) {
      return const Icon(Icons.image, size: 100);
    }

    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } else if (_selectedImagePath != null &&
        _selectedImagePath!.startsWith("data:image")) {
      // 🌐 Web: If image is stored as Base64, display it
      return Image.memory(
        base64Decode(_selectedImagePath!.split(",")[1]),
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    }

    return const Icon(Icons.error, size: 100);
  }

  @override
  void initState() {
    super.initState();
    _filteredProducts = HiveBoxes.getProducts().values.toList();
    _searchController.addListener(_filterProducts);
  }

  /// ✅ Filters products based on search query
  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts =
          HiveBoxes.getProducts().values
              .where((product) => product.name.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEC6B1), // ✅ Matches the AppBar color

      appBar: AppBar(
        title: const Text(
          "Manage Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
          ),
          SizedBox(width: 10),
        ],

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
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 8,
            bottom: 8,
          ), // ✅ Adds padding
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(
                255,
                201,
                55,
                36,
              ).withOpacity(0.8), // ✅ Light background
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context); // ✅ Navigates back
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
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
            const Divider(color:  Color(0xFFC29D7F)),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Product>('products').listenable(),
                builder: (context, Box<Product> box, _) {
                  final allProducts = box.values.toList();
                  final products =
                      _searchController.text.isEmpty
                          ? allProducts
                          : allProducts
                              .where(
                                (product) => product.name.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ),
                              )
                              .toList();
        
                  if (allProducts.isEmpty) {
                    return const Center(child: Text("No products available."));
                  } else if (products.isEmpty) {
                    return const Center(child: Text("No products found."));
                  }
        
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ), // ✅ Added spacing
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
        
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ), // ✅ Extra spacing between cards
                        child: Card(
                          color: Color(0xFFC29D7F),
                          elevation: 10,
                          shadowColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // ✅ Increased border radius
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                              12,
                            ), // ✅ Adjusted inner padding
                            height: 80, // ✅ Adjusted card height
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      product.imagePath.isNotEmpty
                                          ? _displayProductImage(product)
                                          : const Icon(Icons.image, size: 50),
                                ),
                                const SizedBox(
                                  width: 16,
                                ), // ✅ Added spacing between image & text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ), // ✅ Small spacing
                                      Text(
                                        "\₱${product.price.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 26, 88, 29),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                      onPressed: () => _editProduct(product),
                                    ),
                                    Switch(
                                      value: product.isActive,
                                      onChanged:
                                          (value) => _toggleActive(product),
                                      activeColor: Colors.green,
                                      inactiveTrackColor: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _displayProductImage(Product product) {
    if (kIsWeb && product.imagePath.startsWith("data:image")) {
      return Image.memory(
        base64Decode(product.imagePath.split(",")[1]),
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

void _showAddProductDialog() {
  setState(() {
    _nameController.clear();
    _priceController.clear();
    _selectedImagePath = null;
    _webImageBytes = null;
  });

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // ✅ Rounded corners
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDEC6B1), // ✅ Consistent background color
            borderRadius: BorderRadius.circular(15),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Title
                  const Text(
                    "Add Product",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Product Name Input
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Product Name",
                      filled: true,
                      fillColor: Color(0xFFEFE6DD), // ✅ Light fill color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Price Input
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      prefixText: "₱",
                      filled: true,
                      fillColor: Color(0xFFEFE6DD), // ✅ Light fill color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Image Preview
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC29D7F), // ✅ Matches other modals
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImagePath != null || _webImageBytes != null
                        ? _displayImage()
                        : const Icon(Icons.image, size: 100, color: Colors.white),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Pick Image Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // ✅ Button color
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _pickImage();
                      setState(() {});
                    },
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Image"),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Buttons (Cancel & Add Product)
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
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          _addProduct();
                          Navigator.pop(context);
                        },
                        child: const Text("Add Product"),
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

}
