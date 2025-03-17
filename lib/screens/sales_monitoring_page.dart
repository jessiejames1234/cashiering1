import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import '../db/hive_boxes.dart';
import 'package:intl/intl.dart';

class SalesMonitoringPage extends StatefulWidget {
  const SalesMonitoringPage({super.key});

  @override
  State<SalesMonitoringPage> createState() => _SalesMonitoringPageState();
}

class _SalesMonitoringPageState extends State<SalesMonitoringPage> {
  List<Sale> _filteredSales = [];
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _filterSalesByPeriod("Today");
  }

  /// ✅ Fixes filtering logic
void _filterSalesByPeriod(String period) {
  final allSales = HiveBoxes.getSales().values.toList();
  DateTime now = DateTime.now();
  DateTime startDate, endDate;

  switch (period) {
    case "Today":
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case "Last Day":
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      endDate = DateTime(now.year, now.month, now.day);
      break;
    case "This Week":
          startDate = now.subtract(Duration(days: now.weekday + 6)); // Monday of last week
      endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)); // Sunday of last week
      break;
    case "Last Week":
      startDate = now.subtract(Duration(days: now.weekday - 1)); // Monday of this week
      endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)); // Sunday of this week
      break;
    case "This Month":
      startDate = DateTime(now.year, now.month, 1); // First day of the month
      endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1)); // Last second of this month
      break;
    case "Last Month":
      startDate = DateTime(now.year, now.month - 1, 1); // First day of last month
      endDate = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1)); // Last second of last month
      break;
    default:
      return;
  }

  _filteredSales = allSales.where((sale) {
    return sale.date.isAfter(startDate) && sale.date.isBefore(endDate);
  }).toList();

  _totalEarnings = _filteredSales.fold(0.0, (sum, sale) => sum + sale.totalPrice);

  setState(() {});
}


  /// ✅ Added time in sale details
  void _showSaleDetails(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sale Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Date: ${DateFormat.yMMMd().add_jm().format(sale.date)}"), // ✅ Shows date + time
              const Divider(),
              const Text("Ordered Products:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sale.products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(product.name)),
                        Text("x${product.quantity}"),
                        Text("\$${(product.price * product.quantity).toStringAsFixed(2)}"),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Divider(),
              Text(
                "Total Amount: \$${sale.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Monitoring")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                _filterButton("Today"),
                _filterButton("Last Day"),
                _filterButton("This Week"),
                _filterButton("Last Week"),
                _filterButton("This Month"),
                _filterButton("Last Month"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Total Earnings: \$${_totalEarnings.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _filteredSales.isEmpty
                ? const Center(child: Text("No sales recorded for this period."))
                : ListView.builder(
                    itemCount: _filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = _filteredSales[index];
                      return ListTile(
                        title: Text("Date: ${DateFormat.yMMMd().add_jm().format(sale.date)}"), // ✅ Added time
                        subtitle: Text("Total: \$${sale.totalPrice.toStringAsFixed(2)}"),
                        trailing: ElevatedButton(
                          onPressed: () => _showSaleDetails(context, sale),
                          child: const Text("See Details"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String period) {
    return ElevatedButton(
      onPressed: () => _filterSalesByPeriod(period),
      child: Text(period),
    );
  }
}
