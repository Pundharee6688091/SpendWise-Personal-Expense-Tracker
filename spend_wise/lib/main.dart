import 'package:flutter/material.dart';
import 'package:spend_wise/db/api.dart';
import 'page/transaction.dart';

void main() async{
  runApp(const MainApp());
  final api = API();
  await api.fetchData();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', 
        useMaterial3: true,
      ),
      home: const TransactionsScreen(),
    );
  }
}
