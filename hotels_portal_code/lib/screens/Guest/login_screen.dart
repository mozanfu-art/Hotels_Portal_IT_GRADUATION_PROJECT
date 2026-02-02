// This file defines the LoginScreen widget, which provides a user interface for guests to log into the Hotels Portal application.
// It includes form fields for email and password, validation, and authentication via the AuthProvider.

import 'package:flutter/material.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

// LoginScreen is a StatefulWidget that manages the login form and user interactions.
// It allows users to enter their credentials and authenticate to access the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// _LoginScreenState manages the state of the LoginScreen, including form controllers and login logic.
class _LoginScreenState extends State<LoginScreen> {
  // TextEditingController for managing the email input field.
  final TextEditingController emailController = TextEditingController();
  // TextEditingController for managing the password input field.
  final TextEditingController passwordController = TextEditingController();

  // Boolean to toggle password visibility.
  bool _isPasswordVisible = false;

  // _login method handles the authentication process when the login button is pressed.
  // It validates inputs, calls the AuthProvider's signIn method, and handles success or error responses.
  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(
      email,
      password,
      isAdminLogin: false,
    );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      // Navigation will be handled by the AuthWrapper
      Navigator.pushReplacementNamed(context, '/home');

      print("Signed in as guest");
    }
  }

  // _navigateToSignup method navigates the user to the signup screen when they choose to create a new account.
  void _navigateToSignup() {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    // The build method constructs the UI for the login screen, consisting of a header, body with form, and footer.
    return Scaffold(
      backgroundColor: Color(0xFFFFFBF0),
      body: SafeArea(
        child: Column(
          children: [
            // Header section: Displays the screen title with a back button for navigation.
            Container(
              width: double.infinity,
              height: 120,
              color: Color(0xFF004D40),
              padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
              child: Row(
                children: [
                  // Back button to return to the previous screen.
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      // Title text for the login screen.
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // To balance the back button
                ],
              ),
            ),
            // Body section: Contains the login form with input fields and buttons.
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container for the login form, styled with a white background and shadow.
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Welcome message at the top of the form.
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Email input field.
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Password input field, with obscured text for security.
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                          ),
                          SizedBox(height: 32),
                          // Login button to submit the form and authenticate the user.
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text('Login'),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Text button to navigate to the signup screen for new users.
                          TextButton(
                            onPressed: _navigateToSignup,
                            child: Text(
                              "Don't have an account? Sign up",
                              style: TextStyle(
                                color: Color(0xFF004D40),
                                decoration: TextDecoration.underline,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer section: Displays footer text, likely containing app information or copyright.
            const Footer(),
          ],
        ),
      ),
    );
  }
}
