import 'package:flutter/material.dart';
import 'transaction.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionItem item;

  const EditTransactionScreen({super.key, required this.item});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  
  bool isIncome = false;
  late String selectedCategory;
  late DateTime selectedDate;

  // --- UPDATED LISTS ---
  final List<String> expenseCategories = ["Food & Drink", "Transportation", "Rent", "Utilities", "Entertainment"];
  final List<String> incomeCategories = ["Salary", "Investments"];

  @override
  void initState() {
    super.initState();
    String cleanAmount = widget.item.amount.replaceAll(RegExp(r'[^\d.]'), '');
    amountController = TextEditingController(text: cleanAmount);
    noteController = TextEditingController(text: widget.item.title);
    isIncome = !widget.item.isNegative;

    selectedCategory = widget.item.category;
    
    // Fix category matching if valid options changed
    if (isIncome && !incomeCategories.contains(selectedCategory)) {
      selectedCategory = incomeCategories.first;
    } else if (!isIncome && !expenseCategories.contains(selectedCategory)) {
      // Default if not found
      selectedCategory = "Food & Drink";
    }

    selectedDate = DateTime.now(); 
  }

  List<String> get currentCategoryOptions => isIncome ? incomeCategories : expenseCategories;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}";
  }
  
  String _formatFullDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  void _saveTransaction() {
    IconData newIcon;
    Color newColor;

    // --- UPDATED COLOR LOGIC TO MATCH DATABASE ---
    switch (selectedCategory) {
      case "Food & Drink":
        newIcon = Icons.fastfood;
        newColor = const Color(0xFFFFEBEE); // Light Red
        break;
      case "Transportation":
        newIcon = Icons.local_gas_station;
        newColor = const Color(0xFFE3F2FD); // Light Blue
        break;
      case "Rent":
        newIcon = Icons.home;
        newColor = const Color(0xFFFFF3E0); // Light Orange
        break;
      case "Utilities":
        newIcon = Icons.lightbulb;
        newColor = const Color(0xFFE0F2F1); // Light Teal
        break;
      case "Entertainment":
        newIcon = Icons.movie;
        newColor = const Color(0xFFF3E5F5); // Light Purple
        break;
      case "Salary":
        newIcon = Icons.attach_money;
        newColor = const Color(0xFFE8F5E9); // Light Green
        break;
      case "Investments":
        newIcon = Icons.trending_up;
        newColor = const Color(0xFFE0F7FA); // Light Cyan
        break;
      default:
        newIcon = Icons.help_outline;
        newColor = Colors.grey.shade200;
        break;
    }

    TransactionItem updatedItem = TransactionItem(
      id: widget.item.id,
      title: noteController.text.isEmpty ? selectedCategory : noteController.text,
      subtitle: widget.item.subtitle, 
      amount: "${isIncome ? '+' : '-'} \$${amountController.text}",
      isNegative: !isIncome,
      iconBgColor: newColor,
      iconData: newIcon,
      category: selectedCategory, 
      date: _formatDate(selectedDate), 
    );

    Navigator.pop(context, updatedItem);
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
        title: const Text("Edit transaction", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
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
              _buildClickableField(label: "Category", value: selectedCategory, icon: Icons.category_outlined, onTap: _showCategoryPicker),
              const SizedBox(height: 20),
              _buildClickableField(label: "Date", value: _formatFullDate(selectedDate), icon: Icons.calendar_today, onTap: _pickDate),
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5C6BC0), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Category", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: currentCategoryOptions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(currentCategoryOptions[index]),
                      onTap: () {
                        setState(() => selectedCategory = currentCategoryOptions[index]);
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
            if (!currentCategoryOptions.contains(selectedCategory)) {
              selectedCategory = currentCategoryOptions.first;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF1565C0) : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableField({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.white),
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