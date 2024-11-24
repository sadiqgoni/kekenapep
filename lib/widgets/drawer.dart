import 'package:flutter/material.dart';

Drawer buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Colors.yellow[700],
          ),
          accountName: const Text(
            'John Doe',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          accountEmail: const Text(
            'johndoe@gmail.com',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.account_circle,
              size: 50,
              color: Colors.yellow[700],
            ),
          ),
        ),
        _buildDrawerItem(
          icon: Icons.home,
          text: 'Home',
          onTap: () => Navigator.pop(context),
        ),
        _buildDrawerItem(
          icon: Icons.account_circle,
          text: 'Profile',
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => ProfileScreen()),
            // );
          },
        ),
        _buildDrawerItem(
          icon: Icons.settings,
          text: 'Settings',
          onTap: () {
            // Navigate to settings screen
          },
        ),
        _buildDrawerItem(
          icon: Icons.help,
          text: 'Support',
          onTap: () {
            // Navigate to support screen
          },
        ),
      ],
    ),
  );
}

Widget _buildDrawerItem({
  required IconData icon,
  required String text,
  required GestureTapCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.yellow[700]),
    title: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
    ),
    onTap: onTap,
  );
}
