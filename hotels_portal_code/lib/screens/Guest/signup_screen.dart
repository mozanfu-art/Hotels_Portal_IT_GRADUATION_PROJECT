import 'package:flutter/material.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  void _signUp() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.signUp(
        email: email,
        password: password,
        fName: firstName,
        lName: lastName,
        phone: phone,
        birthDate: birthdateController.text.isNotEmpty
            ? DateTime.parse(birthdateController.text)
            : null,
      );

      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      birthdateController.text = picked.toString().split(' ')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: const Color(0xFF004D40),
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Signup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004D40),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'First Name',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: firstNameController,
                                            decoration: InputDecoration(
                                              hintText: 'Enter your first name',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Last Name',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: lastNameController,
                                            decoration: InputDecoration(
                                              hintText: 'Enter your last name',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: emailController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your email',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Phone Number',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: phoneController,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your phone',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Birthdate',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: birthdateController,
                                      readOnly: true,
                                      onTap: _selectDate,
                                      decoration: InputDecoration(
                                        hintText: 'Select your birthdate',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: passwordController,
                                      decoration: InputDecoration(
                                        hintText: 'Create password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Confirm Password',
                                      style: TextStyle(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: confirmPasswordController,
                                      decoration: InputDecoration(
                                        hintText: 'Confirm password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: const OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004D40),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                      horizontal: 64,
                                    ),
                                    textStyle: const TextStyle(fontSize: 18),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text('Sign Up'),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    TextButton(
                                      onPressed: _navigateToLogin,
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Color(0xFF004D40),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: const Footer(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
