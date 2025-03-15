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
  
  String? _selectedImagePath;
  Uint8List? _webImageBytes;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // 🌐 Web: Use FilePicker and store image as bytes
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _webImageBytes = result.files.single.bytes; 
          _selectedImagePath = base64Encode(_webImageBytes!); // Convert to Base64
        });
      }
    } else {
      // 📱 Mobile: Use ImagePicker and store file path
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _webImageBytes = null; 
        });
      }
    }
  }

void _addProduct() {
  final name = _nameController.text;
  final price = double.tryParse(_priceController.text) ?? 0.0;

  if (name.isNotEmpty && price > 0 && (_selectedImagePath != null || _webImageBytes != null)) {
    final product = Product(
      name: name,
      price: price,
      imagePath: kIsWeb && _webImageBytes != null
          ? "data:image/png;base64,${base64Encode(_webImageBytes!)}" // Store Base64 for Web
          : _selectedImagePath!, // Store file path for Mobile
    );

    HiveBoxes.getProducts().add(product);

    _nameController.clear();
    _priceController.clear();
    setState(() {
      _selectedImagePath = null;
      _webImageBytes = null;
    });
  }
}


  void _editProduct(Product product) {
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _selectedImagePath = product.imagePath;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _displayImage(),
            ElevatedButton(
              onPressed: _pickImage,
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
              product.name = _nameController.text;
              product.price = double.tryParse(_priceController.text) ?? product.price;
              if (_selectedImagePath != null) {
                product.imagePath = kIsWeb && _webImageBytes != null
                    ? "data:image/png;base64,$_selectedImagePath"
                    : _selectedImagePath!;
              }
              product.save();

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  void _toggleActive(Product product) {
    product.isActive = !product.isActive;
    product.save();
  }

  Widget _displayImage() {
    if (_selectedImagePath == null && _webImageBytes == null) {
      return const Icon(Icons.image, size: 100);
    }

    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!, height: 100, width: 100, fit: BoxFit.cover);
    } else if (!kIsWeb && _selectedImagePath != null) {
      return Image.file(File(_selectedImagePath!), height: 100, width: 100, fit: BoxFit.cover);
    }

    return const Icon(Icons.error, size: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Products")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
          ),
          _displayImage(),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text("Pick Image"),
          ),
          ElevatedButton(
            onPressed: _addProduct,
            child: const Text("Add Product"),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Product>('products').listenable(),
              builder: (context, Box<Product> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text("No products added."));
                }

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final product = box.getAt(index)!;
                    return ListTile(
                    leading: product.imagePath.isNotEmpty
                        ? _displayProductImage(product) // 🔹 Update this function!
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
    return Image.network(
      product.imagePath, 
      width: 50, 
      height: 50, 
      fit: BoxFit.cover
    );
  } else if (!kIsWeb && product.imagePath.isNotEmpty) {
    return Image.file(
      File(product.imagePath), 
      width: 50, 
      height: 50, 
      fit: BoxFit.cover
    );
  }
  return const Icon(Icons.image, size: 50);
}

}
