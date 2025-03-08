import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keke_fairshare/passenger/services/route_history_service.dart';
import 'package:keke_fairshare/widgets/route_visualization.dart';
import 'package:keke_fairshare/passenger/screens/check_fare_screen.dart';

class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentRoutes = [];
  List<Map<String, dynamic>> _favoriteRoutes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      print('Loading route history data...');
      final recentRoutes = await RouteHistoryService.getRecentRoutes();
      final favoriteRoutes = await RouteHistoryService.getFavoriteRoutes();

      print('Loaded ${recentRoutes.length} recent routes');
      print('Loaded ${favoriteRoutes.length} favorite routes');

      setState(() {
        _recentRoutes = recentRoutes;
        _favoriteRoutes = favoriteRoutes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading route data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading routes: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Routes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellow[700],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.yellow[700],
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRecentRoutesTab(),
            _buildFavoritesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRoutesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No recent routes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recently searched routes will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentRoutes.length,
      itemBuilder: (context, index) {
        final route = _recentRoutes[index];
        return _buildRouteHistoryCard(route);
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No favorite routes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your favorite routes for quick access',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRoutes.length,
      itemBuilder: (context, index) {
        final route = _favoriteRoutes[index];
        return _buildFavoriteRouteCard(route);
      },
    );
  }

  Widget _buildRouteHistoryCard(Map<String, dynamic> route) {
    String formattedDate = 'Unknown date';
    try {
      if (route['timestamp'] != null) {
        final timestamp = route['timestamp'] is String
            ? DateTime.parse(route['timestamp'])
            : DateTime.now();
        formattedDate = DateFormat('MMM d, yyyy - HH:mm').format(timestamp);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    List<dynamic> landmarks = [];
    try {
      landmarks = route['landmarks'] as List? ?? [];
    } catch (e) {
      print('Error getting landmarks: $e');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCheckFare(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₦${route['estimatedFare']}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, size: 20),
                        onPressed: () => _addToFavorites(route),
                        color: Colors.grey[600],
                        tooltip: 'Add to favorites',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${route['source']} → ${route['destination']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Via: ${landmarks.join(' → ')}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteRouteCard(Map<String, dynamic> route) {
    List<dynamic> landmarks = [];
    try {
      landmarks = route['landmarks'] as List? ?? [];
    } catch (e) {
      print('Error getting landmarks: $e');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCheckFare(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route['name'] ??
                          '${route['source']} to ${route['destination']}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, size: 20),
                    onPressed: () => _removeFromFavorites(route['id']),
                    color: Colors.red[400],
                    tooltip: 'Remove from favorites',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${route['source']} → ${route['destination']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Via: ${landmarks.join(' → ')}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCheckFare(Map<String, dynamic> route) {
    List<String> landmarks = [];
    try {
      landmarks =
          (route['landmarks'] as List?)?.map((e) => e.toString()).toList() ??
              [];
    } catch (e) {
      print('Error converting landmarks: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckFareScreen(
          initialSource: route['source'],
          initialDestination: route['destination'],
          initialLandmarks: landmarks,
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _addToFavorites(Map<String, dynamic> route) async {
    try {
      await RouteHistoryService.addToFavorites(
        source: route['source'],
        destination: route['destination'],
        landmarks: List<String>.from(route['landmarks']),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites')),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to favorites: $e')),
      );
    }
  }

  Future<void> _removeFromFavorites(String id) async {
    try {
      await RouteHistoryService.removeFromFavorites(id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing from favorites: $e')),
      );
    }
  }
}
