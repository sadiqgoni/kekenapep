import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFFC107);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  static ThemeData get theme {
    return ThemeData(
      cupertinoOverrideTheme:
          const CupertinoThemeData().copyWith(primaryColor: primaryColor),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionHandleColor: Colors.black,
        selectionColor: primaryColor,
      ),
      // useMaterial3: false,
      hintColor: Colors.grey,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: accentColor,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}
