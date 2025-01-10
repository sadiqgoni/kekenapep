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
        color: const Color(0xFF8E54E9),
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildStickyContent(),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 100.0,
      backgroundColor: const Color(0xFF8E54E9),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 26, bottom: 20),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF2C3E50),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4776E6),
                Color(0xFF8E54E9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyContent() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyWelcomeDelegate(
        maxHeight: 420,
        minHeight: 420,
        child: Container(
          color: const Color.fromARGB(255, 239, 231, 255),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: StreamBuilder<User?>(
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
                              color: const Color(0xFF6B7280),
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
                                  color: const Color(0xFF4776E6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Stats Cards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildStatsRow(
                        firstStat: StatCardData(
                          title: 'Total Users',
                          value: '${_stats['totalUsers']}',
                          icon: Icons.people,
                          color: const Color(0xFF4776E6),
                        ),
                        secondStat: StatCardData(
                          title: 'Total Submissions',
                          value: '${_stats['totalSubmissions']}',
                          icon: Icons.assignment,
                          color: const Color(0xFF8E54E9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsRow(
                        firstStat: StatCardData(
                          title: 'Approved',
                          value: '${_stats['ApprovedSubmissions']}',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF10B981),
                        ),
                        secondStat: StatCardData(
                          title: 'Pending',
                          value: '${_stats['PendingSubmissions']}',
                          icon: Icons.pending_outlined,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Activity Heading
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Recent Activity',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('fares')
              .orderBy('metadata.reviewedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final fares = snapshot.data!.docs;
            if (fares.isEmpty) {
              return Center(
                child: Text(
                  'No recent activity',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              );
            }
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: fares.length,
              itemBuilder: (context, index) => _buildFareCard(
                fares[index].data() as Map<String, dynamic>,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFareCard(Map<String, dynamic> fare) {
    final reviewedBy = fare['reviewedBy'];
    String reviewedByText = 'Unknown';

    if (reviewedBy is Map<String, dynamic>) {
      reviewedByText = reviewedBy['name'] ?? 'Unknown';
    } else if (reviewedBy is String) {
      reviewedByText = reviewedBy;
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          fare['status'] == 'Approved' ? Icons.check_circle : Icons.cancel,
          color: fare['status'] == 'Approved' ? Colors.green : Colors.red,
        ),
        title: Text(
          '${fare['source']} → ${fare['destination']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ₦${fare['fareAmount']}',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'Reviewed by: $reviewedByText',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          '₦${fare['fareAmount']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4776E6),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required StatCardData firstStat,
    required StatCardData secondStat,
  }) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(firstStat)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(secondStat)),
      ],
    );
  }

  Widget _buildStatCard(StatCardData data) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: _StatCard(data: data),
        );
      },
    );
  }
}

class _StickyWelcomeDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;

  _StickyWelcomeDelegate({
    required this.child,
    required this.maxHeight,
    required this.minHeight,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }
}

class StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
          ),
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
