import 'database.dart' as db; // 1. Add 'as db' prefix

class API {
  /// Fetches all available categories.
  Future<List<db.Category>> fetchCategories() async {
    try {
      return await db.getCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Fetches all transactions.
  Future<List<db.Transaction>> fetchTransactions() async {
    try {
      return await db.getTransactions();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Adds a new transaction.
  Future<int> addTransaction(db.Transaction transaction) async {
    try {
      return await db.insertTransaction(transaction);
    } catch (e) {
      print('Error adding transaction: $e');
      return -1;
    }
  }

  /// Updates an existing transaction.
  Future<int> updateTransaction(db.Transaction transaction) async {
    try {
      // 2. Explicitly call the database function using the prefix
      return await db.updateTransaction(transaction); 
    } catch (e) {
      print('Error updating transaction: $e');
      return -1;
    }
  }

  /// Deletes a transaction by ID.
  Future<int> deleteTransaction(int id) async {
    try {
      // 3. Explicitly call the database function using the prefix
      return await db.deleteTransaction(id);
    } catch (e) {
      print('Error deleting transaction: $e');
      return -1;
    }
  }

  /// Gets the financial summary.
  Future<db.FinancialSummary> fetchFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await db.getFinancialSummary(startDate: startDate, endDate: endDate);
    } catch (e) {
      print('Error fetching financial summary: $e');
      return db.FinancialSummary(totalIncome: 0, totalExpense: 0);
    }
  }

  /// Gets the Top N spending categories.
  Future<List<db.CategorySpending>> fetchTopSpendingCategories({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      return await db.getTopSpendingCategories(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      print('Error fetching top categories: $e');
      return [];
    }
  }

  /// Gets the monthly cashflow data.
  Future<List<db.MonthlyCashflow>> fetchMonthlyCashflow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await db.getMonthlyCashflow(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching monthly cashflow: $e');
      return [];
    }
  }
  
  /// Gets the daily cashflow data.
  Future<List<db.MonthlyCashflow>> fetchDailyCashflow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await db.getDailyCashflow(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching daily cashflow: $e');
      return [];
    }
  }
}