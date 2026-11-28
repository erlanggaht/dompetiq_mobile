import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/main_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/widgets/biometric_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.loadSession();
  await BalanceVisibility.load();

  final authService = AuthService();
  final isLoggedIn = await authService.isSessionValid().catchError((_) => true);
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
      navigatorKey: DioClient.navigatorKey,
      routes: {
        '/': (context) => const BiometricGate(child: MainScreen()),
        '/auth/login': (context) => LoginScreen(),
        '/auth/register': (context) => const RegisterScreen(),
        '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
