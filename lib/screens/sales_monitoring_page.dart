import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import '../db/hive_boxes.dart';

class SalesMonitoringPage extends StatelessWidget {
  const SalesMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Monitoring")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Sale>('sales').listenable(), // ✅ Ensure correct reference
        builder: (context, Box<Sale> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No sales recorded yet."));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final sale = box.getAt(index)!;
              return ListTile(
                title: Text(sale.productName),
                subtitle: Text("Total: \$${sale.totalPrice.toStringAsFixed(2)}"),
                trailing: Text("${sale.quantity}x"),
              );
            },
          );
        },
      ),
    );
  }
}
