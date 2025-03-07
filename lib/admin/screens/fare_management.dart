import 'package:intl/intl.dart';
import 'package:keke_fairshare/index.dart';
import 'package:keke_fairshare/services/notification_service.dart';

class FareManagementPage extends StatefulWidget {
  const FareManagementPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FareManagementPageState createState() => _FareManagementPageState();
}

class _FareManagementPageState extends State<FareManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Pending';
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Pending';
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = _firestore.collection('fares');

    // Apply status filter only if it's not 'All'
    if (_selectedFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.orderBy('submittedAt', descending: true).limit(50).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
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
          child: AppBar(
            title: Text(
              'Fare Management',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    style: GoogleFonts.poppins(color: Colors.white),
                    dropdownColor: Theme.of(context).primaryColor,
                    items: ['All', 'Pending', 'Approved', 'Rejected']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.poppins(
                                  color: _selectedFilter == value
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedFilter = newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildFaresList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            'Fare Management',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              style: GoogleFonts.poppins(color: Colors.white),
              dropdownColor: Theme.of(context).primaryColor,
              items: ['All', 'Pending', 'Approved', 'Rejected']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            color: _selectedFilter == value
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedFilter = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(snapshot.error.toString()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFareSubmissionCard(snapshot.data!.docs[index]),
              );
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No fare submissions available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading fares',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFareSubmissionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime submittedAt = DateTime.parse(data['submittedAt']);
    final String formattedDate =
        DateFormat('MMM d, y HH:mm').format(submittedAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.all(20),
        leading: _buildStatusIcon(data['status'] ?? 'Pending'),
        title: Text(
          '${data['source']} → ${data['destination']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '₦${data['fareAmount']}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusChip(data['status'] ?? 'Pending'),
          ],
        ),
        children: [
          _buildDetailSection(data),
          const SizedBox(height: 20),
          _buildActionButtons(doc.id, data['status']),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case 'Approved':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'Rejected':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'Flagged':
        iconData = Icons.flag;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.pending;
        iconColor = Colors.blue;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  Widget _buildDetailSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          'Weather',
          data['weatherConditions'],
          Icons.cloud_outlined,
        ),
        _buildDetailRow(
          'Traffic',
          data['trafficConditions'],
          Icons.traffic_outlined,
        ),
        _buildDetailRow(
          'Passenger Load',
          data['passengerLoad'],
          Icons.group_outlined,
        ),
        _buildDetailRow(
          'Rush Hour',
          data['rushHourStatus'],
          Icons.schedule_outlined,
        ),
        if (data['routeTaken']?.isNotEmpty ?? false)
          _buildDetailRow(
            'Route',
            (data['routeTaken'] as List).join(' → '),
            Icons.route_outlined,
          ),
        if (data['fareContext']?.isNotEmpty ?? false)
          _buildDetailRow(
            'Context',
            data['fareContext'],
            Icons.info_outline,
          ),
        if (data['rejectionReason']?.isNotEmpty ?? false)
          _buildDetailRow(
            'Rejection',
            data['rejectionReason'],
            Icons.cancel_outlined,
            isRejection: true,
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value,
    IconData icon, {
    bool isRejection = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isRejection ? Colors.red : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: isRejection ? Colors.red : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String fareId, String? status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          'Approve',
          Icons.check,
          Colors.green,
          () => _updateFareStatus(fareId, 'Approved'),
          status == 'Approved',
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          'Reject',
          Icons.close,
          Colors.red,
          () => _showRejectionDialog(fareId),
          status == 'Rejected',
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          'Flag',
          Icons.flag,
          Colors.orange,
          () => _updateFareStatus(fareId, 'Flagged'),
          status == 'Flagged',
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isActive,
  ) {
    return ElevatedButton.icon(
      onPressed: isActive ? null : onPressed,
      icon: Icon(icon, size: 12),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return const Color.fromRGBO(244, 67, 54, 1);
      case 'Flagged':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateFareStatus(String fareId, String status,
      [String? reason]) async {
    try {
      print('FareManagement: Starting status update for fare $fareId to $status');
      
      final fareRef =
          FirebaseFirestore.instance.collection('fares').doc(fareId);
      final fare = await fareRef.get();
      final userId = fare.data()?['submitter']?['uid'] as String?;
      final source = fare.data()?['source'];
      final destination = fare.data()?['destination'];

      print('FareManagement: Retrieved fare data - UserId: $userId, Source: $source, Destination: $destination');

      // Get current admin's data
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();
      final adminName = adminDoc.data()?['fullName'] ?? 'Unknown Admin';

      print('FareManagement: Admin info - ID: $adminId, Name: $adminName');

      if (userId == null) {
        throw 'User ID not found for this fare';
      }

      // Update both status fields and metadata with admin info
      print('FareManagement: Updating fare status in Firestore');
      await fareRef.update({
        'status': status,
        'metadata.status': status,
        'metadata.reviewedAt': DateTime.now().toIso8601String(),
        'metadata.reviewedBy': {
          'id': adminId,
          'name': adminName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': {
          'id': adminId,
          'name': adminName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        if (reason != null) 'rejectionReason': reason,
      });
      print('FareManagement: Fare status updated successfully');

      // Create notification
      print('FareManagement: Preparing notification data');
      final notificationService = NotificationService();
      String title;
      String message;
      
      switch (status) {
        case 'Approved':
          title = 'Fare Approved';
          message = 'Your fare from $source to $destination has been approved.';
          break;
        case 'Rejected':
          title = 'Fare Rejected';
          message = 'Your fare from $source to $destination was rejected.' + 
                   (reason != null ? '\nReason: $reason' : '');
          break;
        case 'Flagged':
          title = 'Fare Flagged';
          message = 'Your fare from $source to $destination has been flagged for review.';
          break;
        default:
          title = 'Fare Update';
          message = 'Your fare from $source to $destination has been updated.';
      }

      print('FareManagement: Creating notification - Title: $title, Message: $message');
      await notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: status.toLowerCase(),
        fareId: fareId,
      );
      print('FareManagement: Notification created successfully');

      // Update user statistics
      final userStatsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overview');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final statsDoc = await transaction.get(userStatsRef);
        final currentStats = statsDoc.data() ?? {};

        // Calculate points (only for approved submissions)
        int pointsToAdd = status == 'Approved' ? 3 : 0;

        // Update submission counts
        final newStats = {
          'totalSubmissions': (currentStats['totalSubmissions'] ?? 0),
          'ApprovedSubmissions': (currentStats['ApprovedSubmissions'] ?? 0) +
              (status == 'Approved' ? 1 : 0),
          'PendingSubmissions': (currentStats['PendingSubmissions'] ?? 0) - 1,
          'RejectedSubmissions': (currentStats['RejectedSubmissions'] ?? 0) +
              (status == 'Rejected' ? 1 : 0),
          'points': (currentStats['points'] ?? 0) + pointsToAdd,
          'lastSubmissionAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        transaction.set(userStatsRef, newStats, SetOptions(merge: true));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fare ${status.toLowerCase()} successfully'),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating fare status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectionDialog(String fareId) async {
    _rejectionReasonController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejection Reason',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _rejectionReasonController,
          decoration: InputDecoration(
            hintText: 'Enter reason for rejection',
            hintStyle: GoogleFonts.poppins(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateFareStatus(
                  fareId, 'Rejected', _rejectionReasonController.text);
              // reason: _rejectionReasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Reject', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
