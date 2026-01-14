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
      return 'Password minimal 6 karakter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password harus ada huruf kecil';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus ada huruf besar';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password harus ada angka';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password harus ada simbol';
    }
    return null;
  }

  Future<void> _completeRegistration() async {
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;
    final confirm = confirmCtrl.text;

    if (username.isEmpty) {
      _error('Username wajib diisi');
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      _error(passwordError);
      return;
    }

    if (password != confirm) {
      _error('Password dan konfirmasi tidak sama');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _error('Session habis, silakan login ulang');
      return;
    }

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );
      await supabase.from('profiles').insert({
        'id': user.id,
        'username': username,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      _error('Username sudah digunakan atau terjadi kesalahan');
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      buttonText: "Create new account",
      onButtonPressed: _completeRegistration,
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
                  setState(() =>
                  confirmPasswordVisible = !confirmPasswordVisible);
                },
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}