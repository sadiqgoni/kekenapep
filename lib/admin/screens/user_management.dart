import 'package:flutter/material.dart';

class UserManagementPage extends StatelessWidget {
  final List<Map<String, String>> users = [
    {
      'name': 'John Doe',
      'email': 'john@example.com',
      'status': 'Active',
    },
    {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'status': 'Suspended',
    },
    // Add more entries as needed
  ];

  UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: users.isEmpty
            ? const Center(child: Text('No users available.'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(users[index]);
                },
              ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          user['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user['email']!),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            // Handle user action
          },
          itemBuilder: (BuildContext context) {
            return {'View Profile', 'Suspend User', 'Delete User'}
                .map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
