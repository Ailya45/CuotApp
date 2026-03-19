import 'package:cuot_app/ui/pages/cuotapp_register_page.dart';
import 'package:cuot_app/widget/cuotapp_login_card.dart';
import 'package:cuot_app/widget/cuotapp_logo_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CuotAppLoginPage extends StatelessWidget {
  const CuotAppLoginPage({super.key});

  static const Color kLightGreen = Color(0xFFB9F6CA);
  static const Color kPrimaryGreen = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CuotAppLogoHeader(
                      lightGreen: kLightGreen,
                      primaryGreen: kPrimaryGreen,
                    ),
                    SizedBox(height: 32),
                    CuotAppLoginCard(primaryGreen: kPrimaryGreen),
                    SizedBox(height: 24),
                    _RegisterRow(primaryGreen: kPrimaryGreen),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({required this.primaryGreen});

  final Color primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Aún no tienes cuenta?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CuotAppRegisterPage()),
            );
          },
          style: TextButton.styleFrom(foregroundColor: primaryGreen),
          child: const Text('Regístrate'),
        ),
      ],
    );
  }
}
