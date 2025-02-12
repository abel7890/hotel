import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hotel/AdminDashboardPage.dart';
import 'package:hotel/LoginPage.dart';
import 'package:hotel/SignUpPage.dart';
import 'package:hotel/UserDashboardPage.dart';
import 'firebase_options.dart'; // Firebase configuration file


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Start with the login page
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/user-dashboard': (context) => const UserDashboardPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
