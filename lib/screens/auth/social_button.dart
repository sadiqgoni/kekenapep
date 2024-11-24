import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const SocialButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.black,
      onPressed: onPressed,
      iconSize: 40,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
      splashRadius: 30,
      splashColor: Colors.grey.withOpacity(0.3),
      tooltip:
          'Sign up with ${icon == Icons.g_mobiledata ? 'Google' : 'Facebook'}',
    );
  }
}
