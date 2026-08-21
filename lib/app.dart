import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';

class AutoPlayerApp extends StatelessWidget {
  const AutoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoPlayer AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}