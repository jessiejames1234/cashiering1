import 'package:flutter/material.dart';
import '../db/hive_boxes.dart';
import 'filtered_sales_page.dart';
import 'package:intl/intl.dart';

class SalesMonitoringPage extends StatefulWidget {
  const SalesMonitoringPage({super.key});

  @override
  State<SalesMonitoringPage> createState() => _SalesMonitoringPageState();
}

class _SalesMonitoringPageState extends State<SalesMonitoringPage> {
  final Map<String, double> _earningsData = {};
  final Map<String, int> _productSalesCount = {};

  @override
  void initState() {
    super.initState();
    _calculateEarningsForAllPeriods();
    _calculateBestSellingProducts();
  }

  void _calculateEarningsForAllPeriods() {
    List<String> periods = [
      "Today",
      "Last Day",
      "This Week",
      "Last Week",
      "This Month",
      "Last Month",
    ];
    for (String period in periods) {
      _earningsData[period] = _getTotalEarnings(period);
    }
    setState(() {});
  }

  double _getTotalEarnings(String period) {
    final allSales = HiveBoxes.getSales().values.toList();
    DateTime now = DateTime.now();
    DateTime startDate, endDate;

    switch (period) {
      case "Today":
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case "Last Day":
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case "This Week":
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case "Last Week":
        startDate = now.subtract(Duration(days: now.weekday + 6));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case "This Month":
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        break;
      case "Last Month":
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(seconds: 1));
        break;
      default:
        return 0.0;
    }

    return allSales
        .where(
          (sale) => sale.date.isAfter(startDate) && sale.date.isBefore(endDate),
        )
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  void _calculateBestSellingProducts() {
    final allSales = HiveBoxes.getSales().values.toList();
    _productSalesCount.clear();

    for (var sale in allSales) {
      for (var product in sale.products) {
        _productSalesCount.update(
          product.name,
          (value) => value + product.quantity,
          ifAbsent: () => product.quantity,
        );
      }
    }
    setState(() {});
  }

  void _navigateToFilteredSales(String period) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredSalesPage(period: period),
      ),
    );
  }

String _calculatePercentageChange(String current, String previous) {
  double currentEarnings = _earningsData[current] ?? 0.0;
  double previousEarnings = _earningsData[previous] ?? 0.0;

  // Case 1: both are zero — no change
  if (previousEarnings == 0.0 && currentEarnings == 0.0) {
    return "0%";
  }

  // Case 2: previous was zero, now has earnings — show 100%
  if (previousEarnings == 0.0 && currentEarnings > 0.0) {
    return "+100.00%";
  }

  // Case 3: now is zero, but had earnings before — full drop
  if (currentEarnings == 0.0 && previousEarnings > 0.0) {
    return "-100.00%";
  }

  // Case 4: standard percentage change
  double percentageChange = ((currentEarnings - previousEarnings) / previousEarnings) * 100;

  return "${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(2)}%";
}


void _filterByCustomDateRange() async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFC29D7F),
            onPrimary: Colors.black,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    String label =
        "Sale For: ${DateFormat.yMMMd().format(picked.start)} To ${DateFormat.yMMMd().format(picked.end)}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredSalesPage(
          period: label,
          customStartDate: picked.start,
          customEndDate: picked.end,
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    List<String> periods = [
      "Today",
      "Last Day",
      "This Week",
      "Last Week",
      "This Month",
      "Last Month",
    ];

    var scaffold = Scaffold(
      backgroundColor: const Color(0xFFDEC6B1), // ✅ Matches the AppBar color

      appBar: AppBar(
        title: const Text(
          "Sales Monitoring",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
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

      body: Container(
        color: Color(0xFFDEC6B1), // Second Color (Tan/Brownish)

        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
Center(
  child: ElevatedButton.icon(
    onPressed: _filterByCustomDateRange,
    icon: const Icon(Icons.date_range, color: Colors.black,),
    label: const Text("Filter by Date"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFC29D7F),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 5,
    ),
  ),
),

const SizedBox(height: 12),

              // Earnings Summary
              GridView.builder(
                
                shrinkWrap: true,
                itemCount: periods.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 2.0,
                ),
                itemBuilder: (context, index) {
                  String period = periods[index];
                  String previousPeriod =
                      index + 1 < periods.length
                          ? periods[index + 1]
                          : periods[index];

                  String changeText = _calculatePercentageChange(
                    period,
                    previousPeriod,
                  );
                  double changeValue =
                      double.tryParse(changeText.replaceAll('%', '')) ?? 0.0;
                  Color changeColor =
                      changeValue > 0
                          ? Colors.green
                          : (changeValue < 0
                              ? Colors.red
                              : const Color.fromARGB(255, 82, 80, 80));

                  return GestureDetector(
                    onTap: () => _navigateToFilteredSales(period),
                    child: Card(
                      
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                          elevation: 10, // ✅ Adds a subtle shadow for depth
                          shadowColor: Colors.black,

                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFFC29D7F),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              period,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                                                  Text(
                         "Total Earning", // ✅ Normal text
                      ),
                            Text(
                              "\₱${_earningsData[period]?.toStringAsFixed(2) ?? "0.00"}",
                              style: const TextStyle(
                                color: Color.fromARGB(
                                                        255,
                                                        26,
                                                        88,
                                                        29,
                                                      ),
                                fontSize: 14,
                              ),
                            ),
                            //Text(
                              //"Change: $changeText",
                             // style: TextStyle(
                              //  color: changeColor,
                              //  fontWeight: FontWeight.bold,
                            //  ),
                            //),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Best Selling Products
              const Text(
                "Best Selling Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child:
                    _productSalesCount.isEmpty
                        ? const Center(child: Text("No sales data available."))
                        : ListView.builder(
                          itemCount: _productSalesCount.length,
                          itemBuilder: (context, index) {
                            var sortedProducts =
                                _productSalesCount.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value));

                            final product = sortedProducts[index];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Color(0xFFC29D7F),
                          elevation: 10, // ✅ Adds a subtle shadow for depth
                          shadowColor: Colors.black,

                              child: ListTile(
                                leading: const Icon(
                                  Icons.local_offer,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                                title: Text(product.key),
                                trailing: Text(
                                  "Sold: ${product.value}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
    return scaffold;
  }
}
