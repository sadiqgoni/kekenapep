import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSettingsOption(
              context: context,
              label: 'Manage Admins',
              icon: Icons.admin_panel_settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageAdminsPage()),
                );
              },
            ),
            _buildSettingsOption(
              context: context,
              label: 'App Configurations',
              icon: Icons.settings,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AppConfigurationsPage()),
                );
              },
            ),
            _buildSettingsOption(
              context: context,
              label: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage()),
                );
              },
            ),
            _buildSettingsOption(
              context: context,
              label: 'Terms of Service',
              icon: Icons.article,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class ManageAdminsPage extends StatelessWidget {
  const ManageAdminsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text('Manage Admins Page (Placeholder)'),
      ),
    );
  }
}

class AppConfigurationsPage extends StatelessWidget {
  const AppConfigurationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Configurations'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text('App Configurations Page (Placeholder)'),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text('Privacy Policy Page (Placeholder)'),
      ),
    );
  }
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text('Terms of Service Page (Placeholder)'),
      ),
    );
  }
}
