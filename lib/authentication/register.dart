import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool isLoading = false;
  String? errorText;

  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();

  final supabase = Supabase.instance.client;

  final OutlineInputBorder fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain a special character';
    }
    return null;
  }

  Future<void> _completeRegistration() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorText = null;
    });

    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;
    final confirm = confirmCtrl.text;

    if (username.isEmpty) {
      setState(() {
        errorText = 'Username is required';
        isLoading = false;
      });
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      setState(() {
        errorText = passwordError;
        isLoading = false;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        errorText = 'Password and confirmation do not match';
        isLoading = false;
      });
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        errorText = 'Session expired, please log in again';
        isLoading = false;
      });
      return;
    }

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      await supabase.from('profiles').insert({
        'user_id': user.id,
        'username': username,
        'email': user.email,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() {
        errorText = 'Username already exists or an error occurred';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      buttonText: isLoading ? "Creating..." : "Create New Account",
      onButtonPressed: isLoading ? null : _completeRegistration,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Create Account",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 24),
          const Text("Username"),
          const SizedBox(height: 6),
          TextField(
            controller: usernameCtrl,
            decoration: InputDecoration(
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFF2E64A5),
                  width: 2,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),

          const SizedBox(height: 16),
          const Text("Password"),
          const SizedBox(height: 6),
          TextField(
            controller: passwordCtrl,
            obscureText: !passwordVisible,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFF2E64A5),
                  width: 2,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => passwordVisible = !passwordVisible);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text("Confirm Password"),
          const SizedBox(height: 6),
          TextField(
            controller: confirmCtrl,
            obscureText: !confirmPasswordVisible,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFF2E64A5),
                  width: 2,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  confirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    confirmPasswordVisible =
                    !confirmPasswordVisible;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (errorText != null)
            Center(
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
