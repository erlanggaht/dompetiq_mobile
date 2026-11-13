import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.loadSession();

  final authService = AuthService();
  final isLoggedIn = await authService.isSessionValid();
  final initialRoute = isLoggedIn ? '/' : '/auth/login';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

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
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
