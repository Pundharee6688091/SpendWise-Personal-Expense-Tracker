import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

enum TransactionType { expense, income }

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type; // 'expense' or 'income'
  final int categoryId;
  final DateTime date;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
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
    );
  }
}

class Category {
  final int? id;
  final String name;
  final int colorValue;

  Category({this.id, required this.name, required this.colorValue});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'colorValue': colorValue};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  /// Gets the database instance, initializing it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// Initializes and opens the database.
  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'spendwise_db.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  //Create database tables and insert default data.
  Future _onCreate(Database db, int version) async {
    // Create Categories Table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL
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
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await _insertDefaultCategories(db);
  }
}

Future<void> _insertDefaultCategories(Database db) async {
  List<Category> defaultCategories = [
    // Expenses
    Category(name: 'Food & Drink', colorValue: Colors.red.toARGB32()),
    Category(name: 'Transport', colorValue: Colors.blue.toARGB32()),
    Category(name: 'Rent', colorValue: Colors.orange.toARGB32()),
    Category(name: 'Utilities', colorValue: Colors.teal.toARGB32()),
    Category(name: 'Entertainment', colorValue: Colors.purple.toARGB32()),

    // Income
    Category(name: 'Salary', colorValue: Colors.green.toARGB32()),
    Category(name: 'Investments', colorValue: Colors.cyan.toARGB32()),
  ];

  for (var category in defaultCategories) {
    await db.insert('categories', category.toMap());
  }
}

/// Fetches all categories from the database.
Future<List<Category>> getCategories() async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('categories');
  // Convert List<Map<String, dynamic>> to List<Category>
  return List.generate(maps.length, (i) {
    return Category.fromMap(maps[i]);
  });
}

//Fetches all transactions from the database.
Future<List<Transaction>> getTransactions() async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('transactions');
  // Convert List<Map<String, dynamic>> to List<Transaction>
  return List.generate(maps.length, (i) {
    return Transaction.fromMap(maps[i]);
  });
}

/// Inserts a new transaction into the database.
Future<int> insertTransaction(Transaction transaction) async {
  final db = await DatabaseHelper.instance.database;
  return await db.insert('transactions', transaction.toMap());
}
