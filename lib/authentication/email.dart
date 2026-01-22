  import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/layout.dart';
import 'dart:async';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  return emailRegex.hasMatch(email);
}

class _EmailPageState extends State<EmailPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl = TextEditingController();

  String? errorMessage;

  int? redirectCountdown;
  Timer? redirectTimer;
  bool isLoading = false;
  Future<bool> isEmailRegistered(String email) async {
    final res = await supabase
        .from('profiles')
        .select('user_id')
        .eq('email', email)
        .limit(1);

    return res.isNotEmpty;
  }

  Future<void> _showErrorAndRedirect(String email) async {
    redirectTimer?.cancel();

    setState(() {
      redirectCountdown = 3;
      errorMessage =
      "Email already registered. Redirecting to login in ${redirectCountdown}s...";
    });

    redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (redirectCountdown == null) return;

      if (redirectCountdown! <= 1) {
        timer.cancel();

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => route.isFirst,
          arguments: email,
        );
      } else {
        setState(() {
          redirectCountdown = redirectCountdown! - 1;
          errorMessage =
          "Email already registered. Redirecting to login in ${redirectCountdown}s...";
        });
      }
    });
  }

  Future<void> _sendOtp(String email) async {
    await supabase.auth.signInWithOtp(
      email: email,
    );
  }

  @override
  void dispose() {
    redirectTimer?.cancel();
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return AuthLayout(
      buttonText: isLoading ? "Sending..." : "Send OTP",
      onButtonPressed: isLoading
          ? null
          : () async {
        if (_formKey.currentState!.validate()) {
          final email = emailCtrl.text.trim();

          setState(() {
            isLoading = true;
            errorMessage = null;
          });

          try {
            final exist = await isEmailRegistered(email);
            if (exist) {
              await _showErrorAndRedirect(email);
              return;
            }

            await _sendOtp(email);

            if (!mounted) return;
            Navigator.pushReplacementNamed(
              context,
              '/otp',
              arguments: email,
            );
          } catch (e) {
            setState(() {
              errorMessage = "Failed to send OTP. Please try again.";
            });
          } finally {
            if (mounted) {
              setState(() => isLoading = false);
            }
          }
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Login or Register",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              height: 150,
              child: Center(
                child: Image.asset('assets/icon/email.png'),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Enter your email"),
            const SizedBox(height: 6),

            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                border: field,
                enabledBorder: field,
                focusedBorder: field,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!isValidEmail(value)) {
                  return 'Email is not valid';
                }
                return null;
              },
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
