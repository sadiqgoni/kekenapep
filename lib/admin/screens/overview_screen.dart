import 'package:flutter/material.dart';
import 'package:keke_fairshare/services/admin_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _isLoading = true);
      final stats = await _adminService.getAdminStats();
      final pendingFares = await _adminService.getPendingFaresCount();
      final totalUsers = await _adminService.getTotalUsersCount();

      setState(() {
        _stats = {
          ...stats,
          'pendingFares': pendingFares,
          'totalUsers': totalUsers,
        };
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Overview',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Image.asset(
                  'assets/images/overview_background.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildListDelegate(
                  [
                    _buildStatCard(
                      'Pending Fares',
                      _stats['pendingFares']?.toString() ?? '0',
                      Colors.orange,
                      Icons.pending_actions,
                    ),
                    _buildStatCard(
                      'Total Users',
                      _stats['totalUsers']?.toString() ?? '0',
                      Colors.blue,
                      Icons.people,
                    ),
                    _buildStatCard(
                      'Total Fares',
                      _stats['totalFares']?.toString() ?? '0',
                      Colors.green,
                      Icons.receipt_long,
                    ),
                    _buildStatCard(
                      'Revenue',
                      '₦${_stats['totalRevenue']?.toString() ?? '0'}',
                      Colors.purple,
                      Icons.attach_money,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return _isLoading
        ? SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.yellow[700],
              ),
            ),
          )
        : Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: color)
                      .animate(controller: _animationController)
                      .scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutQuad);
  }

  // Widget _buildShimmerCard() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey[300]!,
  //     highlightColor: Colors.grey[100]!,
  //     child: Card(
  //       elevation: 8,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //       child: const Padding(
  //         padding: EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             CircleAvatar(radius: 20, backgroundColor: Colors.white),
  //             SizedBox(height: 12),
  //             Container(height: 14, width: 80, color: Colors.white),
  //             SizedBox(height: 8),
  //             Container(height: 24, width: 60, color: Colors.white),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
