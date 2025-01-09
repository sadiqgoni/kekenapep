import 'dart:async';

import 'package:keke_fairshare/index.dart';
import '../services/support_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final SupportService _supportService = SupportService();

  late Stream<Map<String, dynamic>> _userDataStream;
  StreamSubscription<Map<String, dynamic>>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _userDataStream = getUserDataStream();
    _userDataSubscription = _userDataStream.listen((_) {});
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      await updateUserProfile(updates);
      if (mounted) {
        _showTopSnackBar('Profile updated successfully');
      }
    } catch (e) {
      _showTopSnackBar('Error updating profile: $e', isError: true);
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Edit Profile',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              initialValue: userData['fullName'] ?? '',
              label: 'Name',
              validator: Validators.validateName,
              onSaved: (value) => _updateProfile({'fullName': value}),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Change Password',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: currentPasswordController,
              label: 'Current Password',
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: newPasswordController,
              label: 'New Password',
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: confirmPasswordController,
              label: 'Confirm New Password',
              obscureText: true,
              validator: (value) {
                if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return Validators.validatePassword(value);
              },
            ),
          ],
        ),
        onSubmit: (values) async {
          try {
            await _authService.changePassword(
              currentPasswordController.text,
              newPasswordController.text,
            );
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            _showTopSnackBar('Password changed successfully');
          } catch (e) {
            _showTopSnackBar('Failed to change password: $e', isError: true);
          }
        },
      ),
    );
  }

  void _showSupportRequestDialog() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Submit Support Request',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: messageController,
              label: 'Describe your issue or request',
              maxLines: 3,
              validator: Validators.validateNotEmpty,
            ),
          ],
        ),
        onSubmit: (values) async {
          try {
            await _supportService
                .submitSupportRequest(messageController.text.trim());
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            _showTopSnackBar('Support request submitted successfully');
          } catch (e) {
            _showTopSnackBar('Failed to submit support request: $e',
                isError: true);
          }
        },
      ),
    );
  }

  void _showTopSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Stream<Map<String, dynamic>> getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: (sink) => sink.close(),
        )
        .handleError((error) {
      print('Error in user data stream: $error');
      return {};
    }).map((snapshot) => snapshot.data() as Map<String, dynamic>? ?? {});
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _userDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: GoogleFonts.poppins()));
          }
          final userData = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(userData),
                const SizedBox(height: 24),
                _buildSectionHeader('Personal Information'),
                const SizedBox(height: 16),
                _buildInfoTile(
                  icon: Icons.person,
                  title: 'Name',
                  subtitle: userData['fullName'] ?? 'Not set',
                  onTap: () => _showEditProfileDialog(userData),
                ),
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Phone',
                  subtitle: userData['phoneNumber'] ?? 'Not available',
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Settings'),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                SwitchListTile(
                  title: Text('Notifications', style: GoogleFonts.poppins()),
                  value: userData['notificationsEnabled'] ?? true,
                  onChanged: (value) =>
                      _updateProfile({'notificationsEnabled': value}),
                  secondary:
                      Icon(Icons.notifications, color: Colors.yellow[700]),
                ),
                _buildSettingsTile(
                  icon: Icons.support_agent,
                  title: 'Support Request',
                  onTap: _showSupportRequestDialog,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Log Out',
                  icon: Icons.logout,
                  color: Colors.red[400]!,
                  onPressed: () async {
                    try {
                      // Cancel stream subscription first
                      await _userDataSubscription?.cancel();
                      _userDataSubscription = null;

                      // Sign out
                      await _authService.signOut();

                      // Navigate to AuthGate after successful sign out
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthGate(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        _showTopSnackBar(
                          'Error signing out: ${e.toString()}',
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    String initials = (userData['fullName'] ?? 'Passenger')
        .toString()
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');

    // Take up to 3 initials (or fewer if less words are present)
    String avatarText =
        initials.length > 3 ? initials.substring(0, 3) : initials;

    return Center(
      child: Column(
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avatarText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userData['fullName'] ?? 'Passenger',
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            userData['phoneNumber'] ?? 'No Phone',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow[700]),
      title:
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins()),
      trailing: onTap != null ? const Icon(Icons.edit, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow[700]),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Custom Widgets

class CustomTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onSaved,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
      validator: validator,
      onSaved: onSaved,
    );
  }
}

class CustomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final Function(Map<String, String>)? onSubmit;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final values = <String, String>{};

    return AlertDialog(
      title:
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Form(
        key: formKey,
        child: content,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();
              Navigator.pop(context);
              onSubmit?.call(values);
            }
          },
          child: Text('Submit', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}

// Validators

class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }
}
