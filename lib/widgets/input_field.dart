import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final double screenWidth;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller; // Added controller parameter

  const InputField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.screenWidth,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
    required String? Function(dynamic value)
        validator, // Added controller to the constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Set the controller here
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFFDB300)),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: screenWidth * 0.038,
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
