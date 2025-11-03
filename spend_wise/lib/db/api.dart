import 'database.dart';

class API
{
  Future<void> fetchData() async
  {
    //Fetch data from an API
    try{
      List<Category> categories = await getCategories();
      for (var category in categories) {
        print('${category.name}');
      }

      print('Fetching transactions...');
      List<Transaction> transactions = await getTransactions();
      if (transactions.isEmpty) {
        print('No transcation found.');
      }
      for (var transaction in transactions) {
        print('Title: ${transaction.title}, Amount: ${transaction.amount}, Type: ${transaction.type}, Date: ${transaction.date}');
      }
    } catch (e) {
      print('Error fetching data: $e');  
    }
  }

  Future<int> addTransaction(Transaction transaction) async {
    try {
      int id = await insertTransaction(transaction);
      print('Transaction added with id: $id');
      return id;
    } catch (e) {
      print('Error adding transaction: $e');
      return -1; // Indicate failure
    }
  }

}