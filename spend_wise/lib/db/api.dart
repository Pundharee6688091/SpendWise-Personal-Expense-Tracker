import 'database.dart' as db;

class API {

  // --- CRUD category --- //
  /// Fetches all categories.
  Future<List<db.Category>> fetchCategories() async {
    try {
      return await db.getCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Adds a new category.
  Future<int> addCategory(db.Category category) async {
    try {
      return await db.insertCategories(category);
    } catch (e) {
      print('Error adding category: $e');
      return -1;
    }
  }

  /// Updates an category.
  Future<int> updateCategory(db.Category category) async {
    try {
      return await db.updateCategories(category); 
    } catch (e) {
      print('Error updating category: $e');
      return -1;
    }
  }

  /// Deletes a category by ID.
  Future<int> deleteCategory(int id) async {
    try {
      return await db.deleteCategories(id);
    } catch (e) {
      print('Error deleting category: $e');
      return -1;
    }
  }


  // --- CRUD transaction --- //
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
      return await db.updateTransaction(transaction); 
    } catch (e) {
      print('Error updating transaction: $e');
      return -1;
    }
  }

  /// Deletes a transaction by ID.
  Future<int> deleteTransaction(int id) async {
    try {
      return await db.deleteTransaction(id);
    } catch (e) {
      print('Error deleting transaction: $e');
      return -1;
    }
  }



  /// Gets the financial summary between start and end date
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

  /// Gets the Top 5 spending categories between start and end date
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

