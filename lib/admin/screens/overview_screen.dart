import 'package:keke_fairshare/index.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminStatsService _statsService = AdminStatsService();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalSubmissions': 0,
    'ApprovedSubmissions': 0,
    'PendingSubmissions': 0,
    'RejectedSubmissions': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getAdminStats();
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _refreshData() async {
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        color: Colors.yellow[700],
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildWelcomeBanner()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 100.0,
      backgroundColor: const Color(0xFFFFFFFF), // Clean white background
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 26, bottom: 20),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF2C3E50), // Dark blue-gray for text
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4776E6), // Rich blue
                Color(0xFF8E54E9), // Purple
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF), // Light blue-tinted background
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4776E6)
                .withOpacity(0.08), // Matching blue from AppBar
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<User?>(
            stream: _auth.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoading();
              }
              final userName = snapshot.data?.displayName ?? 'Admin';
              return Row(
                children: [
                  Text(
                    'Welcome Back, ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: const Color(0xFF6B7280), // Modern gray
                    ),
                  ),
                  Expanded(
                    child: Hero(
                      tag: 'username',
                      child: Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(
                              0xFF4776E6), // Matching blue from AppBar
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedStatCard(
                      'Total Users',
                      '${_stats['totalUsers']}',
                      Icons.people,
                      const Color(0xFF4776E6), // Primary blue
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnimatedStatCard(
                      'Total Submissions',
                      '${_stats['totalSubmissions']}',
                      Icons.assignment,
                      const Color(0xFF8E54E9), // Purple from gradient
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedStatCard(
                      'Approved',
                      '${_stats['ApprovedSubmissions']}',
                      Icons.check_circle_outline,
                      const Color(0xFF10B981), // Modern green
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnimatedStatCard(
                      'Pending',
                      '${_stats['PendingSubmissions']}',
                      Icons.pending_outlined,
                      const Color(0xFFF59E0B), // Modern amber
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 10),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
