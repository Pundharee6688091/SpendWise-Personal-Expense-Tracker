import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// --- MODELS ---

enum TransactionType { expense, income }

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type; // 'expense' or 'income'
  final int categoryId;
  final DateTime date;
  final String note;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note' : note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      type: TransactionType.values.byName(map['type'] as String),
      categoryId: map['categoryId'] as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String? ?? '',
    );
  }
}

class Category {
  final int? id;
  final String name;
  final int colorValue;
  final TransactionType defaultType; // Added to help filter in UI

  Category({this.id, required this.name, required this.colorValue, required this.defaultType});

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'name': name, 
      'colorValue': colorValue,
      'defaultType': defaultType.name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
      defaultType: TransactionType.values.byName(map['defaultType'] as String),
    );
  }
}

// Model for financial summary data
class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
  }) : netBalance = totalIncome - totalExpense;
}

// Model for top spending category insight
class CategorySpending {
  final String categoryName;
  final int colorValue;
  final double totalAmount;

  CategorySpending({
    required this.categoryName,
    required this.colorValue,
    required this.totalAmount,
  });
}

// Model for monthly/daily income/expense totals (Bar Chart Data)
class MonthlyCashflow {
  final int month; // For monthly view (1-12) or daily view (1-31)
  final double totalIncome;
  final double totalExpense;

  MonthlyCashflow({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory MonthlyCashflow.fromMap(Map<String, dynamic> map) {
    return MonthlyCashflow(
      month: map['month'] as int,
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


// --- DATABASE HELPER ---

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  /// Gets the database instance, initializing it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!; 
    
    // NOTE: Deleting the old file ensures that if we added a column (like defaultType), 
    // the new schema is applied correctly.
    _database = await _initDb(deleteExisting: true); 
    
    return _database!;
  }

  Future<Database> _initDb({bool deleteExisting = false}) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'spendwise_db.db');
    
    // Delete the file if deleteExisting is true to ensure the schema update
    if (deleteExisting && await databaseFactory.databaseExists(path)) {
      await deleteDatabase(path);
      print('Old database deleted for schema update.');
    }

    // Version 1 is used since we are deleting and recreating the database.
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Create Categories Table (now includes defaultType)
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        defaultType TEXT NOT NULL
      )
    ''');
    // Create Transactions Table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await _insertDefaultCategories(db);
  }
}

// --- CATEGORY FUNCTIONS ---

Future<void> _insertDefaultCategories(Database db) async {
  List<Category> defaultCategories = [
    // Expenses
    Category(name: 'Food & Drink', colorValue: Colors.red.value, defaultType: TransactionType.expense),
    Category(name: 'Transport', colorValue: Colors.blue.value, defaultType: TransactionType.expense),
    Category(name: 'Rent', colorValue: Colors.orange.value, defaultType: TransactionType.expense),
    Category(name: 'Utilities', colorValue: Colors.teal.value, defaultType: TransactionType.expense),
    Category(name: 'Entertainment', colorValue: Colors.purple.value, defaultType: TransactionType.expense),
    Category(name: 'Shopping', colorValue: Colors.pink.value, defaultType: TransactionType.expense),
    Category(name: 'Others', colorValue: Colors.grey.value, defaultType: TransactionType.expense),

    // Income
    Category(name: 'Salary', colorValue: Colors.green.value, defaultType: TransactionType.income),
    Category(name: 'Investments', colorValue: Colors.cyan.value, defaultType: TransactionType.income),
    Category(name: 'Gift', colorValue: Colors.amber.value, defaultType: TransactionType.income),
  ];

  for (var category in defaultCategories) {
    await db.insert('categories', category.toMap());
  }
}

/// Fetches all categories from the database.
Future<List<Category>> getCategories() async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('categories');
  return List.generate(maps.length, (i) {
    return Category.fromMap(maps[i]);
  });
}

// --- TRANSACTION CRUD FUNCTIONS ---

/// Fetches all transactions from the database, sorted by date descending.
Future<List<Transaction>> getTransactions() async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'transactions',
    orderBy: 'date DESC',
  );
  return List.generate(maps.length, (i) {
    return Transaction.fromMap(maps[i]);
  });
}

/// Inserts a new transaction into the database.
Future<int> insertTransaction(Transaction transaction) async {
  final db = await DatabaseHelper.instance.database;
  return await db.insert('transactions', transaction.toMap());
}

/// Updates an existing transaction.
Future<int> updateTransaction(Transaction transaction) async {
  final db = await DatabaseHelper.instance.database;
  return await db.update(
    'transactions',
    transaction.toMap(),
    where: 'id = ?',
    whereArgs: [transaction.id],
  );
}

/// Deletes a transaction by ID.
Future<int> deleteTransaction(int id) async {
  final db = await DatabaseHelper.instance.database;
  return await db.delete(
    'transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// --- AGGREGATE/INSIGHT FUNCTIONS ---

/// Calculates total income, total expense, and net balance within a date range.
Future<FinancialSummary> getFinancialSummary({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final db = await DatabaseHelper.instance.database;
  final formattedStartDate = startDate.toIso8601String();
  final formattedEndDate = endDate.toIso8601String();

  final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT
      SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS totalIncome,
      SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS totalExpense
    FROM transactions
    WHERE date BETWEEN ? AND ?
  ''', [formattedStartDate, formattedEndDate]);

  final Map<String, dynamic> map = result.first;
  final totalIncome = (map['totalIncome'] as num?)?.toDouble() ?? 0.0;
  final totalExpense = (map['totalExpense'] as num?)?.toDouble() ?? 0.0;

  return FinancialSummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  );
}

/// Calculates the Top 5 spending categories within a date range.
Future<List<CategorySpending>> getTopSpendingCategories({
  required DateTime startDate,
  required DateTime endDate,
  int limit = 5,
}) async {
  final db = await DatabaseHelper.instance.database;
  final formattedStartDate = startDate.toIso8601String();
  final formattedEndDate = endDate.toIso8601String();

  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      c.name AS categoryName,
      c.colorValue AS colorValue,
      SUM(t.amount) AS totalAmount
    FROM transactions t
    INNER JOIN categories c ON t.categoryId = c.id
    WHERE t.type = 'expense' AND t.date BETWEEN ? AND ?
    GROUP BY c.id, c.name, c.colorValue
    ORDER BY totalAmount DESC
    LIMIT ?
  ''', [formattedStartDate, formattedEndDate, limit]);

  return List.generate(maps.length, (i) {
    return CategorySpending(
      categoryName: maps[i]['categoryName'] as String,
      colorValue: maps[i]['colorValue'] as int,
      totalAmount: (maps[i]['totalAmount'] as num).toDouble(),
    );
  });
}

/// Fetches total income and expense broken down by month for a given year.
Future<List<MonthlyCashflow>> getMonthlyCashflow({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final db = await DatabaseHelper.instance.database;
  final formattedStartDate = startDate.toIso8601String();
  final formattedEndDate = endDate.toIso8601String();

  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      CAST(SUBSTR(date, 6, 2) AS INTEGER) AS month,
      SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS totalIncome,
      SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS totalExpense
    FROM transactions
    WHERE date BETWEEN ? AND ?
    GROUP BY month
    ORDER BY month ASC
  ''', [formattedStartDate, formattedEndDate]);

  return List.generate(maps.length, (i) {
    return MonthlyCashflow.fromMap({
      'month': maps[i]['month'],
      'totalIncome': (maps[i]['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (maps[i]['totalExpense'] as num?)?.toDouble() ?? 0.0,
    });
  });
}

/// Fetches total income and expense broken down by day for a given period.
Future<List<MonthlyCashflow>> getDailyCashflow({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final db = await DatabaseHelper.instance.database;
  final formattedStartDate = startDate.toIso8601String();
  final formattedEndDate = endDate.toIso8601String();

  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      CAST(SUBSTR(date, 9, 2) AS INTEGER) AS day,
      SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS totalIncome,
      SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS totalExpense
    FROM transactions
    WHERE date BETWEEN ? AND ?
    GROUP BY day
    ORDER BY day ASC
  ''', [formattedStartDate, formattedEndDate]);

  return List.generate(maps.length, (i) {
    return MonthlyCashflow.fromMap({
      // We use the 'month' field in MonthlyCashflow model to hold the 'day' value (1-31)
      'month': maps[i]['day'], 
      'totalIncome': (maps[i]['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (maps[i]['totalExpense'] as num?)?.toDouble() ?? 0.0,
    });
  });
}


// --- UTILITY FOR COLOR CONVERSION ---
extension ColorExtension on Color {
  int get value {
    return this.value; 
  }
}