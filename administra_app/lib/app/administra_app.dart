import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../screens/login_page.dart';

class AdministraApp extends StatelessWidget {
  const AdministraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Administra+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const LoginPage(),
    );
  }
}
