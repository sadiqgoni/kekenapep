import 'package:keke_fairshare/admin/screens/pending_submissions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  // ... (existing code)
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ... (existing code)

  Widget _buildDashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildDashboardTile(
          title: 'Pending Submissions',
          icon: Icons.pending_actions,
          color: Colors.orange,
          count: _pendingSubmissionsCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PendingSubmissionsScreen(),
              ),
            );
          },
        ),
        // ... other existing tiles ...
      ],
    );
  }

  // ... (rest of the existing code)
}
