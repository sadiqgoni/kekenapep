import 'package:flutter/material.dart';
import 'package:keke_fairshare/widgets/drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.15;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keke Napep Fare Share'),
        backgroundColor: Colors.yellow[700],
      ),
      drawer: buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: (screenWidth > 600) ? 3 : 2, // Responsive layout
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            GridTileWidget(
              icon: Icons.add_circle_outline,
              label: 'Submit Fare',
              iconSize: iconSize,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => SubmitFareScreen()),
                // );
              },
            ),
            GridTileWidget(
              icon: Icons.search,
              label: 'Check Fare',
              iconSize: iconSize,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => CheckFareScreen()),
                // );
              },
            ),
            GridTileWidget(
              icon: Icons.history,
              label: 'Fare History',
              iconSize: iconSize,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => FareHistoryScreen()),
                // );
              },
            ),
            GridTileWidget(
              icon: Icons.account_circle,
              label: 'Profile',
              iconSize: iconSize,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ProfileScreen()),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GridTileWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final VoidCallback onTap;

  const GridTileWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Tooltip(
              message: label, // Accessibility feature
              child: Icon(icon, size: iconSize, color: Colors.yellow[700]),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
