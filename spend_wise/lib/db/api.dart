import 'database.dart';

class API {
  /// Fetches all available categories.
  Future<List<Category>> fetchCategories() async {
    try {
      return await getCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Fetches all transactions.
  Future<List<Transaction>> fetchTransactions() async {
    try {
      return await getTransactions();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Adds a new transaction.
  Future<int> addTransaction(Transaction transaction) async {
    try {
      return await insertTransaction(transaction);
    } catch (e) {
      print('Error adding transaction: $e');
      return -1; // Indicate failure
    }
  }

  /// Updates an existing transaction.
  Future<int> updateTransaction(Transaction transaction) async {
    try {
      return await updateTransaction(transaction);
    } catch (e) {
      print('Error updating transaction: $e');
      return -1; // Indicate failure
    }
  }

  /// Deletes a transaction by ID.
  Future<int> deleteTransaction(int id) async {
    try {
      return await deleteTransaction(id);
    } catch (e) {
      print('Error deleting transaction: $e');
      return -1; // Indicate failure
    }
  }

  /// Gets the financial summary (Income, Expense, Net Balance) for a given period.
  Future<FinancialSummary> fetchFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await getFinancialSummary(startDate: startDate, endDate: endDate);
    } catch (e) {
      print('Error fetching financial summary: $e');
      return FinancialSummary(totalIncome: 0, totalExpense: 0);
    }
  }

  /// Gets the Top N spending categories for a given period.
  Future<List<CategorySpending>> fetchTopSpendingCategories({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      return await getTopSpendingCategories(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      print('Error fetching top categories: $e');
      return [];
    }
  }

  /// Gets the monthly cashflow data (income and expense totals per month) for a given period.
  Future<List<MonthlyCashflow>> fetchMonthlyCashflow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await getMonthlyCashflow(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching monthly cashflow: $e');
      return [];
    }
  }
  
  /// Gets the daily cashflow data (income and expense totals per day) for a given period.
  Future<List<MonthlyCashflow>> fetchDailyCashflow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await getDailyCashflow(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error fetching daily cashflow: $e');
      return [];
    }
  }
}