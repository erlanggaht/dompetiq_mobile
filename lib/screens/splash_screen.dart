import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await DioClient.loadSession();
    await BalanceVisibility.load();

    var isLoggedIn = DioClient.hasSession;
    if (isLoggedIn) {
      try {
        isLoggedIn = await AuthService().isSessionValid();
      } on DioException catch (error) {
        // Keep a stored session during temporary network/server failures.
        isLoggedIn = error.response?.statusCode != 401;
      } catch (_) {
        isLoggedIn = true;
      }
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.accent, colors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colors.accent,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'DompetIQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola keuangan lebih cerdas',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
