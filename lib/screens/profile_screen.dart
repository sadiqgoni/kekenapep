import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keke_fairshare/screens/auth/signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _userService.getCurrentUserData();
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      await _userService.updateUserProfile(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully',
                style: GoogleFonts.poppins()),
          ),
        );
        setState(() {
          _userDataFuture = _userService.getCurrentUserData();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error updating profile: $e', style: GoogleFonts.poppins()),
        ),
      );
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
              initialValue: userData['name'] ?? '',
              label: 'Name',
              validator: Validators.validateName,
              onSaved: (value) => _updateProfile({'name': value}),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: userData['phone'] ?? '',
              label: 'Phone Number',
              validator: Validators.validatePhone,
              onSaved: (value) => _updateProfile({'phone': value}),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Change Password',
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Current Password',
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            SizedBox(height: 16),
            CustomTextField(
              label: 'New Password',
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            SizedBox(height: 16),
            CustomTextField(
              label: 'Confirm New Password',
              obscureText: true,
              validator: Validators.validatePassword,
            ),
          ],
        ),
        onSubmit: (values) => _authService.changePassword(
          values['Current Password']!,
          values['New Password']!,
        ),
      ),
    );
  }

  void _showSupportRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Submit Support Request',
        content: const CustomTextField(
          label: 'Describe your issue or request',
          maxLines: 3,
          validator: Validators.validateNotEmpty,
        ),
        onSubmit: (values) => _userService.submitSupportRequest(
            values['Describe your issue or request'] ?? ''),
      ),
    );
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
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
                  subtitle: userData['name'] ?? 'Not set',
                  onTap: () => _showEditProfileDialog(userData),
                ),
                _buildInfoTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: userData['email'] ?? 'Not available',
                ),
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Phone Number',
                  subtitle: userData['phone'] ?? 'Not set',
                  onTap: () => _showEditProfileDialog(userData),
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
                  onPressed: () => _authService.signOut(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Implement profile picture change
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.yellow[100],
                  backgroundImage: userData['profilePicture'] != null
                      ? NetworkImage(userData['profilePicture'])
                      : const AssetImage('assets/images/banana.png')
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.edit, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData['name'] ?? 'User',
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            userData['email'] ?? 'No email',
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

  const CustomTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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

// Services

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();

      if (!doc.exists) {
        // Create initial document if it doesn't exist
        await userDoc.set({
          'name': user.displayName ?? 'User',
          'email': user.email,
          'notificationsEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return (await userDoc.get()).data() ?? {};
    }
    return {};
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set(updates, SetOptions(merge: true)); // Merge updates
    }
  }

  Future<void> submitSupportRequest(String message) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("No user is currently signed in.");
      }

      await _firestore.collection('support_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      print("Support request submitted successfully.");
    } catch (e) {
      print("Error submitting support request: $e");
      rethrow;
    }
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    // ignore: use_build_context_synchronously
    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
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

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Add more specific phone number validation if needed
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
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
