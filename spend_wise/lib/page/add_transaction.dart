import 'package:flutter/material.dart';
import '../db/api.dart';
import '../db/database.dart';
import '../main.dart'; 

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final API _api = API(); 

  late TextEditingController amountController;
  late TextEditingController noteController;

  bool isLoading = true;
  bool isIncome = false;
  Category? selectedCategory;
  late DateTime selectedDate;

  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    noteController = TextEditingController();
    selectedDate = DateTime.now();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.fetchCategories();
      if (mounted) {
        setState(() {
          _expenseCategories = cats
              .where((c) => c.defaultType == TransactionType.expense)
              .toList();
          _incomeCategories = cats
              .where((c) => c.defaultType == TransactionType.income)
              .toList();

          if (!isIncome && _expenseCategories.isNotEmpty) {
            selectedCategory = _expenseCategories.first;
          } else if (isIncome && _incomeCategories.isNotEmpty) {
            selectedCategory = _incomeCategories.first;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Category> get currentCategoryOptions =>
      isIncome ? _incomeCategories : _expenseCategories;

  String _formatFullDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _addTransaction() async {
    if (amountController.text.trim().isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount and select a category")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null) return;

    setState(() => isLoading = true);

    try {
      final newTransaction = Transaction(
        title: noteController.text.isEmpty
            ? selectedCategory!.name
            : noteController.text,
        amount: amount,
        type: isIncome ? TransactionType.income : TransactionType.expense,
        categoryId: selectedCategory!.id!,
        date: selectedDate,
        note: '', 
      );

      await _api.addTransaction(newTransaction);
      globalRefreshTrigger.value++;

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error adding transaction: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add transaction",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
                  const Text(
                    "USD",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  IntrinsicWidth(
                    child: TextField(
                      controller: amountController,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "0",
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
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
                value: selectedCategory?.name ?? "Select Category",
                icon: selectedCategory != null 
                    ? IconData(selectedCategory!.iconCodePoint, fontFamily: 'MaterialIcons')
                    : Icons.category_outlined,
                onTap: _showCategoryPicker,
              ),
              const SizedBox(height: 20),
              _buildClickableField(
                label: "Date",
                value: _formatFullDate(selectedDate),
                icon: Icons.calendar_today,
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Note",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF5C6BC0)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _showCategoryPicker() {
    final options = currentCategoryOptions;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Category",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: options.isEmpty
                    ? const Center(child: Text("No categories found"))
                    : ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final cat = options[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(cat.colorValue).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                                color: Color(cat.colorValue),
                              ),
                            ),
                            title: Text(cat.name),
                            onTap: () {
                              setState(() {
                                selectedCategory = cat;
                              });
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
            if (isIncome && _incomeCategories.isNotEmpty) {
              selectedCategory = _incomeCategories.first;
            } else if (!isIncome && _expenseCategories.isNotEmpty) {
              selectedCategory = _expenseCategories.first;
            } else {
              selectedCategory = null;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF1565C0) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
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