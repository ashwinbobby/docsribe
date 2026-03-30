import 'package:flutter/material.dart';
import 'ui/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocScribe',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}