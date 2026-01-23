import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zapp/auth/auth_gate.dart';
import 'package:zapp/routes/route_observer.dart';
import 'authentication/welcome.dart';
import 'authentication/login.dart';
import 'authentication/email.dart';
import 'authentication/otp.dart';
import 'authentication/register.dart';
import 'password/forgot.dart';
import 'password/verify.dart';
import 'password/reset.dart';
import 'pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ZAPP",
      navigatorObservers: [routeObserver],
      home: const AuthGate(),
      routes: {
        "/login": (context) => LoginPage(),
        "/email": (context) => EmailPage(),
        "/otp": (context) =>  OTPPage(),
        "/register": (context) => RegisterPage(),
        "/forgot": (context) => ForgotPage(),
        "/verify": (context) => VerifyPage(),
        "/reset": (context) =>  ResetPage(),
        // "/homepage": (context) => HomePage()
      },
    );
  }
}
