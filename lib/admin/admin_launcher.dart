import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_main.dart';

class AdminLauncher extends StatefulWidget {
  const AdminLauncher({super.key});

  @override
  State<AdminLauncher> createState() => _AdminLauncherState();
}

class _AdminLauncherState extends State<AdminLauncher> {
  final _keySequence = <LogicalKeyboardKey>[];
  final _adminSequence = [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.keyA,
  ];
  
  @override
  void initState() {
    super.initState();
    _setupKeyboardListener();
  }

  void _setupKeyboardListener() {
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      _keySequence.add(event.logicalKey);
      
      // Keep only the last N keys where N is the length of admin sequence
      if (_keySequence.length > _adminSequence.length) {
        _keySequence.removeAt(0);
      }

      // Check if the sequences match
      if (_keySequence.length == _adminSequence.length) {
        bool matches = true;
        for (int i = 0; i < _adminSequence.length; i++) {
          if (_keySequence[i] != _adminSequence[i]) {
            matches = false;
            break;
          }
        }
        
        if (matches) {
          _launchAdminApp();
        }
      }
    }
  }

  void _launchAdminApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AdminApp(),
      ),
    );
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget is invisible and just listens for the key combination
    return const SizedBox.shrink();
  }
}
