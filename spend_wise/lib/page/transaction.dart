import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/api.dart';
import '../db/database.dart'; 
import 'edit_transaction.dart';

// --- Data Models ---

// UI-Specific Model (Adapts Database Data for Display)
class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;
  final Color iconBgColor;
  final IconData iconData;
  final String category;
  final String dateHeader; // "Today", "Sep 25"
  final DateTime rawDate;  // For sorting

  TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
    required this.iconBgColor,
    required this.iconData,
    required this.category,
    required this.dateHeader,
    required this.rawDate,
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
  // API Instance
  final API _api = API();
  
  int selectedCategoryIndex = 0;
  bool _isLoading = true;

  // Lists to hold DB data
  List<String> categoryNames = ["All"]; 
  List<TransactionItem> allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads Categories and Transactions from SQLite and merges them
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Categories first (needed to resolve IDs)
      final List<Category> dbCategories = await _api.fetchCategories();
      
      // Map Categories by ID for fast lookup (O(1))
      final Map<int, Category> categoryMap = {
        for (var cat in dbCategories) cat.id!: cat
      };

      // Update the horizontal selector list
      List<String> loadedNames = ["All"];
      loadedNames.addAll(dbCategories.map((c) => c.name));

      // 2. Fetch Transactions
      final List<Transaction> dbTransactions = await _api.fetchTransactions();

      // 3. Convert Database Models to UI Models
      final List<TransactionItem> uiItems = dbTransactions.map((t) {
        // Find the linked category
        final category = categoryMap[t.categoryId];
        
        // Defaults if category was deleted (safety check)
        final String catName = category?.name ?? "Unknown";
        final int iconCode = category?.iconCodePoint ?? Icons.help_outline.codePoint;
        final int colorVal = category?.colorValue ?? Colors.grey.value;

        // Format Amount
        final String amountStr = "${t.type == TransactionType.income ? '+' : '-'} \$${t.amount.toStringAsFixed(2)}";
        
        // Format Date
        final String dateStr = _formatDateForHeader(t.date);

        return TransactionItem(
          id: t.id.toString(),
          title: t.title,
          // If note is empty, show category name as subtitle
          subtitle: catName,
          amount: amountStr,
          isNegative: t.type == TransactionType.expense,
          iconBgColor: Color(colorVal).withOpacity(0.2), // Lighten the stored color
          iconData: IconData(iconCode, fontFamily: 'MaterialIcons'), // USE DB ICON
          category: catName,
          dateHeader: dateStr,
          rawDate: t.date,
        );
      }).toList();

      // 4. Update State
      if (mounted) {
        setState(() {
          categoryNames = loadedNames;
          allTransactions = uiItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading transaction data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper to format dates like "Today" or "Sep 25"
  String _formatDateForHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return "Today";
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    }
    return DateFormat('MMM dd').format(date);
  }

  /// Filtering and Grouping Logic
  List<DaySection> get currentSections {
    List<TransactionItem> filteredItems;
    
    // 1. Filter by Category
    if (selectedCategoryIndex == 0) {
      filteredItems = List.from(allTransactions);
    } else {
      String selectedCategory = categoryNames[selectedCategoryIndex];
      filteredItems = allTransactions.where((item) => item.category == selectedCategory).toList();
    }

    // 2. Sort by Date (Newest first)
    filteredItems.sort((a, b) => b.rawDate.compareTo(a.rawDate));

    // 3. Group into Sections
    List<DaySection> sections = [];
    for (var item in filteredItems) {
      var existingSectionIndex = sections.indexWhere((s) => s.headerTitle == item.dateHeader);
      if (existingSectionIndex != -1) {
        sections[existingSectionIndex].items.add(item);
      } else {
        sections.add(DaySection(item.dateHeader, [item]));
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
        title: const Text("Transactions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Category Selector
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryNames.length,
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
                          categoryNames[index],
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
              
              // List of Transactions
              Expanded(
                child: currentSections.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No transactions found",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
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
        // Navigation to Edit Screen
        final updatedItem = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionScreen(item: item),
          ),
        );
        
        // If we return from Edit Screen (whether saved or deleted), reload the DB data
        if (updatedItem != null) {
           _loadData();
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
                  Text(item.subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
