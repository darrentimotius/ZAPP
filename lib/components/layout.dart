import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget content;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AuthLayout({
    super.key,
    required this.content,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: content,
              ),
            ),
            if (buttonText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onButtonPressed == null
                          ? Colors.grey
                          : const Color(0xFF2E64A5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(buttonText!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
