import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/admin/screens/fare_management_screen.dart';
import 'package:keke_fairshare/screens/fare_history.dart';
import 'package:keke_fairshare/screens/submit_fare_screen.dart';
import 'package:keke_fairshare/screens/check_fare_screen.dart';
import 'package:keke_fairshare/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Home', 'icon': Icons.home},
    {'title': 'Rides', 'icon': Icons.directions_car},
    {'title': 'Profile', 'icon': Icons.person},
    {'title': 'Settings', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildWelcomeBanner()),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildMainGrid(screenWidth, iconSize),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120.0,
      backgroundColor: Colors.yellow[700],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'KeKe FairShare',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.yellow[600]!, Colors.yellow[800]!],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          onPressed: () {
            // Handle notifications
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<User?>(
            stream: _auth.authStateChanges(),
            builder: (context, snapshot) {
              final userName = snapshot.data?.displayName ?? 'Guest';
              return Text(
                'Welcome, $userName!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to do today?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(double screenWidth, double iconSize) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (screenWidth > 600) ? 3 : 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildListDelegate([
        _buildAnimatedGridTile(
          icon: Icons.add_circle_outline,
          label: 'Submit Fare',
          iconSize: iconSize,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubmitFareScreen()));
          },
        ),
        _buildAnimatedGridTile(
          icon: Icons.search,
          label: 'Check Fare',
          iconSize: iconSize,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CheckFareScreen()));
          },
        ),
        _buildAnimatedGridTile(
          icon: Icons.history,
          label: 'Fare History',
          iconSize: iconSize,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FareHistoryScreen()));
          },
        ),
        _buildAnimatedGridTile(
          icon: Icons.account_circle,
          label: 'Profile',
          iconSize: iconSize,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FareManagementPage()));
          },
        ),
      ]),
    );
  }

  Widget _buildAnimatedGridTile({
    required IconData icon,
    required String label,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return Hero(
      tag: label,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.yellow[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellow[700],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            switch (index) {
              case 0:
                // We're already on the home screen, so no navigation needed
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
                break;
            }
          });
        },
      ),
    );
  }
}
