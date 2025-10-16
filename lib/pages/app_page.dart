import 'package:blink_delivery_project/pages/login.dart';
import 'package:blink_delivery_project/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF3B30),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 400,
              height: 400,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              style: TextButton.styleFrom(
                fixedSize: Size(350, 50),
                foregroundColor: Color(0xFFFF3B30),
                backgroundColor: Color(0xFFFFFFFF),
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: ('Inner'),
                ),
              ),
              child: Text('เข้าสู่ระบบ'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              style: TextButton.styleFrom(
                fixedSize: Size(350, 50),
                foregroundColor: Color(0xFFFF3B30),
                backgroundColor: Color(0xFFFFFFFF),
                textStyle: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('สมัครสมาชิก'),
            ),
          ),
        ],
      ),
    );
  }
}
