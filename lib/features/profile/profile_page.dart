import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zapp/core/cache/user_cache.dart';
import 'account_detail.dart';
import 'package:zapp/features/support/contact_us.dart';
import '../password/change_password.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool notificationEnabled = true;
  static const Color primaryBlue = Color(0xFF053886);

  User? user;
  String? username;
  String? email;
  Timer? _retryTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _retryTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadUserProfile(),
    );
  }

  Future<void> _loadUserProfile() async {
    if (UserCache.isReady) {
      setState(() {
        user = UserCache.user;
        username = UserCache.username;
        email = UserCache.email;
      });
      return;
    }

    if (_isFetching) return;

    _isFetching = true;
    try{
      final supabase = Supabase.instance.client;

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await supabase
          .from('profiles')
          .select('username, fullname, avatar_url')
          .eq('user_id', currentUser.id)
          .single();

      UserCache.user = currentUser;
      UserCache.email = currentUser.email;
      UserCache.username = response['username'];
      UserCache.fullname = response['fullname'];
      UserCache.avatarUrl = response['avatar_url'];

      if (!mounted) return;
      setState(() {
        user = currentUser;
        email = currentUser.email;
        username = response['username'];
      });

      _retryTimer?.cancel();
    } catch(e) {
      debugPrint('Profile Page: fetch failed, will retry...');
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Log out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await Supabase.instance.client.auth.signOut();
                UserCache.clear();

                if (!mounted) return;

                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFF0000),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: UserCache.avatarUrl != null &&
                      UserCache.avatarUrl!.isNotEmpty
                      ? NetworkImage(UserCache.avatarUrl!)
                      : const AssetImage("assets/icon/profile.jpg")
                      as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Detail Personal'),

            _menuItem(
              icon: Icons.person,
              title: 'Account Details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountDetailsPage(),
                  ),
                );
              },
            ),
            _divider(),

            _menuItem(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(),
                  ),
                 );
                },
            ),

            _sectionTitle('Other'),

            _menuItem(
              icon: Icons.contact_support,
              title: 'Contact Us',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactUsPage(),
                  ),
                );
              },
            ),
            _divider(),

            _menuItem(
              icon: Icons.logout,
              title: 'Log out',
              isLogout: true,
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.grey.shade200,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Color(0xFFFF0000) : primaryBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Color(0xFFFF0000) : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryBlue),
      title: Text(title),
      trailing: Switch(
        value: notificationEnabled,
        activeColor: primaryBlue,
        onChanged: (value) {
          setState(() {
            notificationEnabled = value;
          });
        },
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1),
    );
  }
}
