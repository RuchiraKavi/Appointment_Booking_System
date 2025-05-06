import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:appointment_booking_system/Ex_pages/customerlogin.dart';
import 'package:appointment_booking_system/Int_pages/admin_home.dart';
import 'package:appointment_booking_system/Int_pages/admin_manage.dart';
import 'package:appointment_booking_system/Int_pages/customer_manage.dart';
import 'package:appointment_booking_system/Int_pages/service_manage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/customer': (context) => const CustomerScreen(),
        '/service': (context) => const ServiceScreen(),
      },
    );
  }
}
