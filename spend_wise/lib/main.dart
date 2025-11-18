import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

// Screens
import 'page/dashboard.dart';
import 'page/transaction.dart';
import 'page/catagory.dart';
import 'page/add_transaction.dart';
import 'page/profile.dart';

// Data/API
import 'db/api.dart';
import 'db/database.dart';

// Global API instance and refresh trigger used across screens
final API globalApi = API();
final ValueNotifier<int> globalRefreshTrigger = ValueNotifier<int>(0);

// --- MAIN APPLICATION SETUP ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Database
  await DatabaseHelper.instance.database;

  // 2. Insert Mock Data
  await _insertInitialData();

  // 3. Launch App with Dashboard as Home
  runApp(const SpendWiseApp());
}

// Helper to insert initial data for demonstration
Future<void> _insertInitialData() async {
  final api = globalApi;
  final categories = await api.fetchCategories();

  // Only proceed if categories exist and no transactions are currently present
  if (categories.isEmpty) return;
  final existingTransactions = await api.fetchTransactions();
  if (existingTransactions.isNotEmpty) return;

  final Map<String, Category> categoryMap = {
    for (var c in categories) c.name: c
  };

  // Define key categories
  final food = categoryMap['Food & Drink']!;
  final rent = categoryMap['Rent']!;
  final utilities = categoryMap['Utilities']!;
  final transport = categoryMap['Transport']!;
  final entertainment = categoryMap['Entertainment']!;
  final shopping = categoryMap['Shopping']!;
  final salary = categoryMap['Salary']!;
  final others = categoryMap['Others']!;

  final now = DateTime.now();
  final random = Random();

  // --- Helper Functions for Date Generation ---

  // Generate a date near the start of the current month, X months ago
  DateTime _startOfMonth(int monthsAgo) {
    final date = DateTime(now.year, now.month - monthsAgo, 1);
    // Ensure the date is always before today's date if monthsAgo is 0
    final day = random.nextInt(monthsAgo == 0 ? now.day - 1 : 28) + 1;
    return DateTime(now.year, now.month - monthsAgo, day);
  }

  // Generate a random date within the last 4 months
  DateTime _randomDateInLastFourMonths() {
    return now.subtract(Duration(days: random.nextInt(120) + 1));
  }

  // --- Fixed Income and Expense (Past 4 months) ---
  for (int i = 0; i < 4; i++) {
    final date = _startOfMonth(i);

    // 1. Monthly Income
    await api.addTransaction(Transaction(
      title: 'Monthly Salary Deposit',
      amount: 5500.00,
      type: TransactionType.income,
      categoryId: salary.id!,
      date: date.add(const Duration(days: 10)), // Payday around the 10th
      note: 'Paycheck for ${DateFormat('MMMM').format(date)}',
    ));

    // 2. Fixed Rent Expense
    await api.addTransaction(Transaction(
      title: 'Apartment Rent Payment',
      amount: 1500.00,
      type: TransactionType.expense,
      categoryId: rent.id!,
      date: date.add(const Duration(days: 5)), // Rent day around the 5th
      note: 'Housing payment',
    ));

    // 3. Variable Utilities Expense
    await api.addTransaction(Transaction(
      title: 'Electricity & Internet Bill',
      amount: 110.00 + random.nextDouble() * 40,
      type: TransactionType.expense,
      categoryId: utilities.id!,
      date: date.add(const Duration(days: 20)),
      note: 'Utility payments',
    ));
  }

  // --- Variable Expenses (Total of 80 transactions for volume) ---
  for (int i = 0; i < 80; i++) {
    Category expenseCategory;
    String title;
    double amount;

    // Use weights to ensure Food and Shopping are the top spending areas
    int weight = random.nextInt(100);
    if (weight < 30) {
      // 30% Food
      expenseCategory = food;
      title = random.nextBool() ? 'Restaurant Lunch' : 'Weekly Groceries Run';
      amount = 7.0 + random.nextDouble() * 55;
    } else if (weight < 50) {
      // 20% Shopping
      expenseCategory = shopping;
      title = random.nextBool() ? 'New Shoes' : 'Online Store Purchase';
      amount = 25.0 + random.nextDouble() * 120;
    } else if (weight < 65) {
      // 15% Transport
      expenseCategory = transport;
      title = random.nextBool() ? 'Gas Refill' : 'Public Transit Pass';
      amount = 4.0 + random.nextDouble() * 50;
    } else if (weight < 80) {
      // 15% Entertainment
      expenseCategory = entertainment;
      title =
          random.nextBool() ? 'Concert Ticket' : 'Monthly Gaming Subscription';
      amount = 10.0 + random.nextDouble() * 60;
    } else {
      // 20% Others/Misc
      expenseCategory = others;
      title = random.nextBool() ? 'Charity Donation' : 'Haircut';
      amount = 15.0 + random.nextDouble() * 70;
    }

    await api.addTransaction(Transaction(
      title: title,
      amount: double.parse(amount.toStringAsFixed(2)),
      type: TransactionType.expense,
      categoryId: expenseCategory.id!,
      date: _randomDateInLastFourMonths(),
      note: '',
    ));
  }
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: Builder(builder: (context) {
        return DashboardScreen(
          api: globalApi,
          refreshTrigger: globalRefreshTrigger,

          // --- Navigation Callbacks ---
          onNavigate: (index) async {
            if (index == 1) {
              // Transactions List
              if (index == 1) {
                // Transactions List
                // 1. Wait for the TransactionsScreen to pop
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (c) => const TransactionsScreen()));

                // 2. ALWAYS trigger the global refresh on return
                globalRefreshTrigger.value++;
              }
            }
            
          },

          // --- UPDATE: Add Transaction Logic ---
          onShowAddTransaction: () async {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (c) => const AddTransactionScreen()));
            // No manual setState needed here because AddTransactionScreen
            // updates the globalRefreshTrigger value directly.
          },
        );
      }),
    );
  }
}
