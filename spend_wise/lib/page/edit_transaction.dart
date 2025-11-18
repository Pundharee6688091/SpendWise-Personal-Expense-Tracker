import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/api.dart';        // Import your API
import '../db/database.dart';   // Import your DB Models
import 'transaction.dart';      // Import for TransactionItem
import 'delete_transaction.dart'; // Import Delete Screen

class EditTransactionScreen extends StatefulWidget {
  final TransactionItem item;

  const EditTransactionScreen({super.key, required this.item});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final API _api = API(); // API Instance
  
  late TextEditingController amountController;
  late TextEditingController noteController;

  bool isIncome = false;
  bool isLoading = true; // Loading state for fetching categories
  
  late String selectedCategoryName;
  late DateTime selectedDate;

  // Store full category objects from DB
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    String cleanAmount = widget.item.amount.replaceAll(RegExp(r'[^\d.]'), '');
    amountController = TextEditingController(text: cleanAmount);
    noteController = TextEditingController(text: widget.item.title); // Using title as note/description
    
    isIncome = !widget.item.isNegative;
    selectedCategoryName = widget.item.category;
    selectedDate = widget.item.rawDate; // Use the raw date passed from TransactionItem

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.fetchCategories();
      setState(() {
        _allCategories = cats;
        isLoading = false;
        
        // Ensure selected category exists in the loaded list, fallback if not
        if (!_allCategories.any((c) => c.name == selectedCategoryName)) {
           if (_allCategories.isNotEmpty) {
             selectedCategoryName = _allCategories.first.name;
           }
        }
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() => isLoading = false);
    }
  }

  // Filter categories based on the toggle (Income vs Expense)
  List<String> get currentCategoryOptions {
    TransactionType type = isIncome ? TransactionType.income : TransactionType.expense;
    return _allCategories
        .where((c) => c.defaultType == type)
        .map((c) => c.name)
        .toList();
  }

  Future<void> _saveTransaction() async {
    if (amountController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // 1. Find the Category ID based on the selected name
      final categoryObj = _allCategories.firstWhere(
        (c) => c.name == selectedCategoryName,
        orElse: () => _allCategories.first,
      );

      // 2. Parse Amount
      double amount = double.tryParse(amountController.text) ?? 0.0;

      // 3. Create Database Model
      Transaction t = Transaction(
        id: int.parse(widget.item.id), // Convert String ID back to Int
        title: noteController.text.isEmpty ? selectedCategoryName : noteController.text,
        amount: amount,
        type: isIncome ? TransactionType.income : TransactionType.expense,
        categoryId: categoryObj.id!,
        date: selectedDate,
        note: noteController.text, 
      );

      // 4. Update in DB
      await _api.updateTransaction(t);

      if (mounted) {
        // Return true to indicate a change occurred
        Navigator.pop(context, true); 
      }
    } catch (e) {
      print("Error updating: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTransaction() async {
  //Push the custom DeleteTransactionScreen
  final bool? deleted = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DeleteTransactionScreen(item: widget.item),
    ),
  );

  // 2. If the delete screen returns 'true' (meaning it deleted successfully),
  // close the Edit screen as well to go back to the list.
  if (deleted == true) {
    if (mounted) {
      Navigator.pop(context, true); 
    }
  }
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
        title: const Text("Edit transaction",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          // Added Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteTransaction,
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Enter amount", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("USD", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(width: 10),
                    IntrinsicWidth(
                      child: TextField(
                        controller: amountController,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(border: InputBorder.none),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      _buildToggleButton("Expense", !isIncome),
                      _buildToggleButton("Income", isIncome),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildClickableField(
                  label: "Category", 
                  value: selectedCategoryName, 
                  icon: Icons.category_outlined, 
                  onTap: _showCategoryPicker
                ),
                const SizedBox(height: 20),
                _buildClickableField(
                  label: "Date", 
                  value: DateFormat('MMM dd, yyyy').format(selectedDate), 
                  icon: Icons.calendar_today, 
                  onTap: _pickDate
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text("Note", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                     const SizedBox(height: 8),
                     TextField(
                       controller: noteController,
                       decoration: InputDecoration(
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5C6BC0))),
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // --- Helper Methods ---

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF5C6BC0),
                onPrimary: Colors.white,
                onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _showCategoryPicker() {
    // Ensure we display categories relevant to the current Income/Expense toggle
    final options = currentCategoryOptions;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Category",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: options.isEmpty 
                ? const Center(child: Text("No categories found for this type."))
                : ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(options[index]),
                      onTap: () {
                        setState(() => selectedCategoryName = options[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isIncome = text == "Income";
            // Reset category to default if current selection doesn't match new type
            if (!currentCategoryOptions.contains(selectedCategoryName)) {
              if (currentCategoryOptions.isNotEmpty) {
                selectedCategoryName = currentCategoryOptions.first;
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
              borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF1565C0) : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableField(
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Text(value, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
