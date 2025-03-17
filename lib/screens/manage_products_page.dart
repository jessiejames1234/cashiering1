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
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Product"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Product Name",
                  ),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _selectedImagePath != null || _webImageBytes != null
                    ? _displayImage()
                    : const Icon(Icons.image, size: 100),
                ElevatedButton(
                  onPressed: () async {
                    await _pickImage();
                    setState(() {});
                  },
                  child: const Text("Change Image"),
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
                  final newName = _nameController.text.trim();
                  final newPrice =
                      double.tryParse(_priceController.text) ?? product.price;

                  // ✅ Ensure new name is unique (excluding the same product)
                  bool nameExists = HiveBoxes.getProducts()
                      .values
                      .any((p) =>
                          p.name.toLowerCase() == newName.toLowerCase() &&
                          p.key != product.key);

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
                    product.imagePath = kIsWeb && _webImageBytes != null
                        ? "data:image/png;base64,${base64Encode(_webImageBytes!)}"
                        : _selectedImagePath!;
                  }

                  product.save();
                  Navigator.pop(context);
                  setState(() {});

                  // ✅ Show success message with product name
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Product '$newName' updated successfully!"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
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
      appBar: AppBar(
        title: const Text("Manage Products"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      body: Column(
        children: [
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
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, Box<Product> box, _) {
                // ✅ Get all products
                final allProducts = box.values.toList();

                // ✅ Apply search filter
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading:
                          product.imagePath.isNotEmpty
                              ? _displayProductImage(product)
                              : const Icon(Icons.image, size: 50),
                      title: Text(product.name),
                      subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editProduct(product),
                          ),
                          Switch(
                            value: product.isActive,
                            onChanged: (value) => _toggleActive(product),
                            activeColor: Colors.green,
                            inactiveTrackColor: Colors.red,
                          ),
                        ],
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
        return StatefulBuilder(
          // ✅ Allow UI updates inside the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Product"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Product Name",
                    ),
                  ),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Price"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),

                  // ✅ Display selected image dynamically
                  _selectedImagePath != null || _webImageBytes != null
                      ? _displayImage()
                      : const Icon(Icons.image, size: 100),

                  ElevatedButton(
                    onPressed: () async {
                      await _pickImage();
                      setState(() {}); // ✅ Update UI after selecting an image
                    },
                    child: const Text("Pick Image"),
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
                    _addProduct();
                    Navigator.pop(context);
                  },
                  child: const Text("Add Product"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
