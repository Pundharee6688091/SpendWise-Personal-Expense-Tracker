import 'package:flutter/material.dart';
import 'edit_transaction.dart';
import 'add_transaction.dart';

// --- Data Models ---

class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;
  final Color iconBgColor;
  final IconData iconData;
  final String category;
  final String date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
    required this.iconBgColor,
    required this.iconData,
    required this.category,
    required this.date,
  });
}

class DaySection {
  final String headerTitle;
  final List<TransactionItem> items;

  DaySection(this.headerTitle, this.items);
}

// --- Screen Widget ---

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int selectedCategoryIndex = 0;

  // Updated to match your Database List
  final List<String> categories = [
    "All",
    "Food & Drink",
    "Transportation",
    "Rent",
    "Utilities",
    "Entertainment",
    "Salary",
    "Investments"
  ];

  // --- MASTER LIST ---
  List<TransactionItem> allTransactions = [
    // Today
    TransactionItem(
      id: "1",
      title: "Shell Station",
      subtitle: "Gas & Oil",
      amount: "- \$45.00",
      isNegative: true,
      iconBgColor: const Color(0xFFE3F2FD), // Light Blue (Transportation)
      iconData: Icons.local_gas_station,
      category: "Transportation",
      date: "Today",
    ),
    TransactionItem(
      id: "2",
      title: "Paypal",
      subtitle: "Freelance Payment",
      amount: "+ \$80.00",
      isNegative: false,
      iconBgColor: const Color(0xFFE8F5E9), // Light Green (Salary/Earnings)
      iconData: Icons.paypal,
      category: "Salary",
      date: "Today",
    ),
    TransactionItem(
      id: "3",
      title: "Stock Return",
      subtitle: "Dividends",
      amount: "+ \$150.00",
      isNegative: false,
      iconBgColor: const Color(0xFFE0F7FA), // Light Cyan (Investments)
      iconData: Icons.trending_up,
      category: "Investments",
      date: "Today",
    ),
    TransactionItem(
      id: "4",
      title: "Netflix",
      subtitle: "Subscription",
      amount: "- \$12.00",
      isNegative: true,
      iconBgColor: const Color(0xFFF3E5F5), // Light Purple (Entertainment)
      iconData: Icons.movie,
      category: "Entertainment",
      date: "Today",
    ),

    // Sep 25
    TransactionItem(
      id: "5",
      title: "KFC",
      subtitle: "Lunch",
      amount: "- \$12.50",
      isNegative: true,
      iconBgColor: const Color(0xFFFFEBEE), // Light Red (Food & Drink)
      iconData: Icons.fastfood,
      category: "Food & Drink",
      date: "Sep 25",
    ),
    TransactionItem(
      id: "6",
      title: "Starbucks",
      subtitle: "Coffee",
      amount: "- \$5.50",
      isNegative: true,
      iconBgColor: const Color(0xFFFFEBEE), // Light Red (Food & Drink)
      iconData: Icons.coffee,
      category: "Food & Drink",
      date: "Sep 25",
    ),

    // Sep 01
    TransactionItem(
      id: "7",
      title: "Apartment Rent",
      subtitle: "Monthly Rent",
      amount: "- \$800.00",
      isNegative: true,
      iconBgColor: const Color(0xFFFFF3E0), // Light Orange (Rent)
      iconData: Icons.home,
      category: "Rent",
      date: "Sep 01",
    ),
    TransactionItem(
      id: "8",
      title: "Electric Bill",
      subtitle: "Monthly Utility",
      amount: "- \$120.00",
      isNegative: true,
      iconBgColor: const Color(0xFFE0F2F1), // Light Teal (Utilities)
      iconData: Icons.lightbulb,
      category: "Utilities",
      date: "Sep 01",
    ),
  ];

  List<DaySection> get currentSections {
    List<TransactionItem> filteredItems;
    if (selectedCategoryIndex == 0) {
      filteredItems = allTransactions;
    } else {
      String selectedCategory = categories[selectedCategoryIndex];
      filteredItems = allTransactions
          .where((item) => item.category == selectedCategory)
          .toList();
    }

    List<DaySection> sections = [];
    for (var item in filteredItems) {
      var existingSectionIndex =
          sections.indexWhere((s) => s.headerTitle == item.date);
      if (existingSectionIndex != -1) {
        sections[existingSectionIndex].items.add(item);
      } else {
        sections.add(DaySection(item.date, [item]));
      }
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text("Transactions",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedCategoryIndex;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategoryIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          border: isSelected
                              ? const Border(
                                  bottom: BorderSide(
                                      color: Color(0xFF5C6BC0), width: 2))
                              : null,
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? const Color(0xFF5C6BC0)
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: currentSections.length,
                  itemBuilder: (context, index) =>
                      _buildDaySection(currentSections[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(DaySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(section.headerTitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 15),
        const Divider(height: 1, color: Colors.black12),
        const SizedBox(height: 15),
        ...section.items.map((item) => _buildTransactionTile(item)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionItem item) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionScreen(item: item),
          ),
        );

        if (result == null) return;

        if (result is Map<String, dynamic> && result['action'] == 'delete') {
          final id = result['id'] as String;
          setState(() {
            allTransactions.removeWhere((element) => element.id == id);
          });
        } else if (result is TransactionItem) {
          setState(() {
            final index =
                allTransactions.indexWhere((element) => element.id == item.id);
            if (index != -1) {
              allTransactions[index] = result;
            }
          });
        }
      },
      child: Container(
        color: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                  color: item.iconBgColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(item.iconData, color: Colors.black54, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              item.amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: item.isNegative ? Colors.black : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
