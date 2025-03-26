import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../db/hive_boxes.dart';

class FilteredSalesPage extends StatefulWidget {
  final String period;
final DateTime? customStartDate;
final DateTime? customEndDate;

const FilteredSalesPage({
  super.key,
  required this.period,
  this.customStartDate,
  this.customEndDate,
});

  @override
  State<FilteredSalesPage> createState() => _FilteredSalesPageState();
}

class _FilteredSalesPageState extends State<FilteredSalesPage> {
  List<Sale> _filteredSales = [];
  double _totalEarnings = 0.0;
  double _previousEarnings = 0.0;
  String _comparisonText = "";

  @override
  void initState() {
    super.initState();
    _filterSalesByPeriod(widget.period);
  }

  void _filterSalesByPeriod(String period) {
    final allSales = HiveBoxes.getSales().values.toList();
    DateTime now = DateTime.now();
    DateTime startDate, endDate, prevStartDate, prevEndDate;
    if (widget.customStartDate != null && widget.customEndDate != null) {
      _filteredSales =
          HiveBoxes.getSales().values.where((sale) {
            return sale.date.isAfter(widget.customStartDate!) &&
                sale.date.isBefore(
                  widget.customEndDate!.add(const Duration(days: 1)),
                );
          }).toList();

      _totalEarnings = _filteredSales.fold(
        0.0,
        (sum, sale) => sum + sale.totalPrice,
      );

      _previousEarnings = 0.0;
      _comparisonText = "";
      setState(() {});
      return;
    }
    switch (period) {
      case "Today":
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        prevStartDate = startDate.subtract(const Duration(days: 1));
        prevEndDate = startDate;
        _comparisonText = "Compared to Last Day";
        break;
      case "Last Day":
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        endDate = DateTime(now.year, now.month, now.day);
        prevStartDate = startDate.subtract(const Duration(days: 1));
        prevEndDate = startDate;
        _comparisonText = "Compared to This Day";
        break;
      case "This Week":
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        prevStartDate = startDate.subtract(const Duration(days: 7));
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        _comparisonText = "Compared to Last Week";
        break;
      case "Last Week":
        startDate = now.subtract(Duration(days: now.weekday + 6));
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        prevStartDate = startDate.subtract(const Duration(days: 7));
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        _comparisonText = "Compared to This Week";
        break;
      case "This Month":
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        prevStartDate = DateTime(now.year, now.month - 1, 1);
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        _comparisonText = "Compared to Last Month";
        break;
      case "Last Month":
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(seconds: 1));
        prevStartDate = DateTime(now.year, now.month - 2, 1);
        prevEndDate = startDate.subtract(const Duration(seconds: 1));
        _comparisonText = "Compared to This Month";
        break;
      default:
        return;
    }

    _filteredSales =
        allSales.where((sale) {
          return sale.date.isAfter(startDate) && sale.date.isBefore(endDate);
        }).toList();

    _totalEarnings = _filteredSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalPrice,
    );

    _previousEarnings = allSales
        .where(
          (sale) =>
              sale.date.isAfter(prevStartDate) &&
              sale.date.isBefore(prevEndDate),
        )
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);

    setState(() {});
  }

  String _calculatePercentageChange() {
    if (_previousEarnings == 0.0) {
      return _totalEarnings > 0
          ? "+100.00%"
          : "-100.00%"; // 🔻 Now correctly shows -100%
    }

    double percentageChange =
        ((_totalEarnings - _previousEarnings) / _previousEarnings) * 100;

    return percentageChange >= 0
        ? "+${percentageChange.toStringAsFixed(2)}%" // 🔼 Green for increase
        : "${percentageChange.toStringAsFixed(2)}%"; // 🔻 Red for decrease
  }

  void _showSaleDetails(BuildContext context, Sale sale) {
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
              color: const Color(0xFFDEC6B1), // ✅ Full background color
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Title
                const Text(
                  "Sale Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // ✅ Date Section
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFC29D7F), // ✅ Light blue background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Date: ${DateFormat.yMMMd().add_jm().format(sale.date)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Ordered Products",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(color: Color(0xFFC29D7F)),

                // ✅ Product List with Background
                Column(
                  children:
                      sale.products.map((product) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(
                              0xFFC29D7F,
                            ), // ✅ Light background for each row
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "x${product.quantity}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 150),
                              Text(
                                "\₱${(product.price * product.quantity).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
                    color: const Color(0xFFC29D7F), // ✅ Background color
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
                          style: TextStyle(
                            color: Colors.black,
                          ), // ✅ Label color
                        ),
                        TextSpan(
                          text:
                              "\₱${sale.totalPrice.toStringAsFixed(2)}", // ✅ Price value
                          style: TextStyle(
                            color:
                                sale.totalPrice > 0
                                    ? Color.fromARGB(255, 26, 88, 29)
                                    : Colors.red, // ✅ Dynamic color
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Close Button
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String changeText = _calculatePercentageChange();
    double changeValue = double.tryParse(changeText.replaceAll('%', '')) ?? 0.0;
    Color changeColor =
        changeValue > 0
            ? Colors.green
            : (changeValue < 0 ? Colors.red : Colors.grey);

    return Scaffold(
      backgroundColor: const Color(0xFFDEC6B1), // ✅ Matches the AppBar color

      appBar: AppBar(
        title: Text(
          "${widget.period}",
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
        toolbarHeight: 80, // ✅ Increased height to add more bottom padding
        shadowColor: Colors.black,
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
              color: Color.fromARGB(255, 201, 55, 36), // ✅ Light background
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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // ✅ Main text color
                      height: 2.5, // ✅ Ensures consistent text height
                    ),
                    children: [
                      const TextSpan(
                        text: "Total Earnings: ", // ✅ Normal text
                      ),
                      WidgetSpan(
                        alignment:
                            PlaceholderAlignment
                                .middle, // ✅ Aligns inline with text height
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFC29D7F,
                            ), // ✅ Background color for amount
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "\₱${_totalEarnings.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(
                                255,
                                26,
                                88,
                                29,
                              ), // ✅ Text color for contrast
                              height:
                                  1.5, // ✅ Ensures consistent height alignment
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
          Expanded(
            child:
                _filteredSales.isEmpty
                    ? const Center(
                      child: Text("No sales recorded for this period."),
                    )
                    : ListView.builder(
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = _filteredSales[index];
                        return Card(
                          elevation: 10, // ✅ Adds a subtle shadow for depth
                          shadowColor: Colors.black,

                          color: Color(0xFFC29D7F),
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(
                              "Date: ${DateFormat.yMMMd().add_jm().format(sale.date)}",
                            ),
subtitle: RichText(
  text: TextSpan(
    style: DefaultTextStyle.of(context).style,
    children: [
      const TextSpan(
        text: "Total: ",
        style: TextStyle(
          color: Colors.black,
        ),
      ),
      TextSpan(
        text: "₱${sale.totalPrice.toStringAsFixed(2)}",
        style: const TextStyle(
          color: Color.fromARGB(
                                255,
                                26,
                                88,
                                29,
                              ), // ,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),

                            trailing: ElevatedButton(
                              onPressed: () => _showSaleDetails(context, sale),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  174,
                                  130,
                                  95,
                                ), // ✅ Brownish background color

                                foregroundColor: const Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ), // ✅ White text color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // ✅ Slightly rounded corners
                                ),
                                elevation: 5,
                                shadowColor: Colors.black,
                                // ✅ Adds a subtle shadow for depth
                              ),
                              child: const Text(
                                "See Details",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
