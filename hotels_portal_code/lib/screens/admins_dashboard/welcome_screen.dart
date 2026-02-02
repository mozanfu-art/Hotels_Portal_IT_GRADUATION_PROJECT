import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004d40),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://firebasestorage.googleapis.com/v0/b/graduation-project-5f333.firebasestorage.app/o/AppImages%2Fhotelicon.png?alt=media&token=3fc911dd-db95-48f1-8366-51d2f7555cf4',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Hotels Portal',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'The Ministry of Tourism',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Republic of Sudan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFBF0),
                foregroundColor: const Color(0xFF004d40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
