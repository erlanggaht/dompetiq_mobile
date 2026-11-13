import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  DioClient.debugEnv();
  await DioClient.loadSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dompetiq',
      routes: {
        '/': (context) => HomeScreen(),
        '/auth/login': (context) => LoginScreen(),
        '/auth/register': (context) => const RegisterScreen(),
        '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      initialRoute: '/auth/login',
      debugShowCheckedModeBanner: false,
    );
  }
}
