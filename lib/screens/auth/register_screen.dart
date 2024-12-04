import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/screens/auth/signin_screen.dart';
import 'package:keke_fairshare/screens/auth/social_button.dart';
import 'package:keke_fairshare/screens/home_screen.dart';
import 'package:keke_fairshare/services/auth/auth_service.dart';
import 'package:keke_fairshare/widgets/header_section.dart';
import 'package:keke_fairshare/widgets/input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog('Passwords do not match!');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        User? user = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          // Update user profile with full name
          await user.updateDisplayName(_fullNameController.text.trim());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        _showErrorDialog('Registration Error: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: GoogleFonts.poppins(color: const Color(0xFFFDB300))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                HeaderSection(
                  title: "Register",
                  subtitle: "Create your account",
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.03,
                  ),
                  child: Column(
                    children: <Widget>[
                      InputField(
                        hintText: "Full Name",
                        icon: Icons.person_outline,
                        screenWidth: screenWidth,
                        controller: _fullNameController,
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      InputField(
                        hintText: "Email",
                        icon: Icons.email_outlined,
                        screenWidth: screenWidth,
                        controller: _emailController,
                        validator: (value) => !value!.contains('@')
                            ? 'Please enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      InputField(
                        hintText: "Password",
                        icon: Icons.lock_outline,
                        screenWidth: screenWidth,
                        obscureText: !_isPasswordVisible,
                        controller: _passwordController,
                        validator: (value) => value!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFFDB300),
                          ),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 20),
                      InputField(
                        hintText: "Confirm Password",
                        icon: Icons.lock_outline,
                        screenWidth: screenWidth,
                        obscureText: !_isConfirmPasswordVisible,
                        controller: _confirmPasswordController,
                        validator: (value) => value != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFFFDB300),
                          ),
                          onPressed: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDB300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                              horizontal: screenWidth * 0.25),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black)
                            : Text(
                                "Register",
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Text("Or sign up with", style: GoogleFonts.poppins()),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SocialButton(
                            icon: Icons.g_mobiledata,
                            onPressed: () {
                              // Handle Google Sign-In
                            },
                            color: const Color(0xFFFDB300),
                          ),
                          const SizedBox(width: 20),
                          SocialButton(
                            icon: Icons.facebook,
                            onPressed: () {
                              // Handle Facebook Sign-In
                            },
                            color: const Color(0xFFFDB300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Have an account? ",
                              style: GoogleFonts.poppins()),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInScreen()),
                            ),
                            child: Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFDB300),
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
