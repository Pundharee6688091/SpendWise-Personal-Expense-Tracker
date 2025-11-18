import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

enum TransactionType { expense, income } // 2 transaction type

// transaction
class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
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
      'note': note,
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

// category
class Category {
  final int? id;
  final String name;
  final int colorValue;
  final TransactionType defaultType;
  final int iconCodePoint;

  Category({
    this.id,
    required this.name,
    required this.colorValue,
    required this.defaultType,
    required this.iconCodePoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'defaultType': defaultType.name,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
      defaultType: TransactionType.values.byName(map['defaultType'] as String),
      iconCodePoint: map['iconCodePoint'] as int,
    );
  }
}

// table for financial summary data
class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
  }) : netBalance = totalIncome - totalExpense;
}

// table for top spending category
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

// table for Bar Chart Data
class MonthlyCashflow {
  final int month;
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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  /// get db create one if it does not exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'spendwise_db.db');

    // call func _onCreate if bd doesn't exist
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // create db
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        defaultType TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL 
      )
    ''');
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


Future<void> _insertDefaultCategories(Database db) async {

  const Color foodColor = const Color(0xFF4FC3F7);
  const Color shoppingColor = const Color(0xFF81D4FA);
  const Color transportColor = const Color(0xFF9FA8DA);
  const Color rentColor = Color(0xFF64B5F6);
  const Color utilitiesColor = const Color(0xFFC942D8);
  const Color entertainmentColor = const Color(0xFFC658D2);
  const Color othersColor = Colors.grey;

  const Color salaryColor = Colors.green;
  const Color investmentsColor = Colors.cyan;
  const Color giftColor = Colors.amber;

  List<Category> defaultCategories = [
    // Expenses
    Category(
        name: 'Food & Drink',
        colorValue: foodColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.fastfood.codePoint),
    Category(
        name: 'Shopping',
        colorValue: shoppingColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.shopping_bag.codePoint),
    Category(
        name: 'Transport',
        colorValue: transportColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.directions_bus.codePoint),
    Category(
        name: 'Rent',
        colorValue: rentColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.home.codePoint),
    Category(
        name: 'Utilities',
        colorValue: utilitiesColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.lightbulb_outline.codePoint),
    Category(
        name: 'Entertainment',
        colorValue: entertainmentColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.movie_filter.codePoint),
    Category(
        name: 'Others',
        colorValue: othersColor.value,
        defaultType: TransactionType.expense,
        iconCodePoint: Icons.category_outlined.codePoint),

    // Income
    Category(
        name: 'Salary',
        colorValue: salaryColor.value,
        defaultType: TransactionType.income,
        iconCodePoint: Icons.work.codePoint),
    Category(
        name: 'Investments',
        colorValue: investmentsColor.value,
        defaultType: TransactionType.income,
        iconCodePoint: Icons.trending_up.codePoint),
    Category(
        name: 'Gift',
        colorValue: giftColor.value,
        defaultType: TransactionType.income,
        iconCodePoint: Icons.card_giftcard.codePoint),
  ];

  for (var category in defaultCategories) {
    await db.insert('categories', category.toMap());
  }
}

// --- CATAGORY CRUD FUNCTIONS ---
Future<List<Category>> getCategories() async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('categories');
  return List.generate(maps.length, (i) {
    return Category.fromMap(maps[i]);
  });
}

Future<int> insertCategories(Category category) async {
  final db = await DatabaseHelper.instance.database;
  return await db.insert('categories', category.toMap());
}

Future<int> updateCategories(Category category) async {
  final db = await DatabaseHelper.instance.database;

  var map = category.toMap();
  map.remove('id');

  return await db.update(
    'categories',
    map,
    where: 'id = ?',
    whereArgs: [category.id],
  );
}

Future<int> deleteCategories(int id) async {
  final db = await DatabaseHelper.instance.database;
  return await db.delete(
    'categories',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// --- TRANSACTION CRUD FUNCTIONS ---
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

Future<int> insertTransaction(Transaction transaction) async {
  final db = await DatabaseHelper.instance.database;
  return await db.insert('transactions', transaction.toMap());
}

Future<int> updateTransaction(Transaction transaction) async {
  final db = await DatabaseHelper.instance.database;

  var map = transaction.toMap();
  map.remove('id');

  return await db.update(
    'transactions',
    map,
    where: 'id = ?',
    whereArgs: [transaction.id],
  );
}

Future<int> deleteTransaction(int id) async {
  final db = await DatabaseHelper.instance.database;
  return await db.delete(
    'transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
}


// --- AGGREGATE/INSIGHT FUNCTIONS ---

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
      'month': maps[i]['day'],
      'totalIncome': (maps[i]['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'totalExpense': (maps[i]['totalExpense'] as num?)?.toDouble() ?? 0.0,
    });
  });
}