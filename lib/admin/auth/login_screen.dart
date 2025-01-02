import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/admin/screens/dashboard_screen.dart';
import 'package:keke_fairshare/services/admin_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCreatingAccount = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isCurrentUserAdmin();
    if (isAdmin && mounted) {
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    }
  }

  Future<void> _handleAuthentication() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isCreatingAccount) {
        await _adminService.createAdminAccount(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin account created successfully')),
          );
        }
      }

      final success = await _adminService.signInAsAdmin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success) {
        throw 'Invalid admin credentials';
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/dashboard',
          (route) => false, // Clear all routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingAccount ? 'Create Admin Account' : 'Admin Login'),
        automaticallyImplyLeading: false, // Remove back arrow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAuthentication,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isCreatingAccount ? 'Create Account' : 'Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isCreatingAccount = !_isCreatingAccount;
                      });
                    },
              child: Text(_isCreatingAccount
                  ? 'Already have an account? Login'
                  : 'Create new admin account'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Go to Passenger App'),
            ),
          ],
        ),
      ),
    );
  }
}
