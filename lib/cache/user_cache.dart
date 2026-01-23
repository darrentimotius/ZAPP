import 'package:supabase_flutter/supabase_flutter.dart';

class UserCache {
  static User? user;
  static String? username;
  static String? email;

  static bool get isReady =>
      user != null && username != null && email != null;

  static void clear() {
    user = null;
    username = null;
    email = null;
  }
}