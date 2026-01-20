import 'package:flutter/material.dart';

class UserInfoPage extends StatelessWidget {
  UserInfoPage({Key? key}) : super(key: key);

  final TextEditingController fullNameController =
  TextEditingController(text: 'Darren Samuel Nathan');
  final TextEditingController emailController =
  TextEditingController(text: 'Darrensamuelnathan@gmail.com');
  final TextEditingController usernameController =
  TextEditingController(text: 'Darren SN');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ===== TITLE =====
            const Text(
              'Account Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // ===== FULL NAME =====
            const Text(
              'Full Name',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ===== EMAIL =====
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ===== USERNAME =====
            const Text(
              'Username',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),

            const Spacer(),

            // ===== SAVE BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5DAA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
