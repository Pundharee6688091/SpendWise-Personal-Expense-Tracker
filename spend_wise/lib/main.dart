import 'package:flutter/material.dart';
import 'package:spend_wise/db/api.dart';

void main() async{
  runApp(const MainApp());
  final api = API();
  await api.fetchData();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
