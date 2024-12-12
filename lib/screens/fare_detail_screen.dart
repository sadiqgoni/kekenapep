import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;

class FareDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fare;
  const FareDetailScreen({Key? key, required this.fare}) : super(key: key);

  @override
  _FareDetailScreenState createState() => _FareDetailScreenState();
}

class _FareDetailScreenState extends State<FareDetailScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    if (widget.fare['status'] == 'Approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String formatValue(dynamic value) {
    if (value == null) return 'Not specified';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  Widget _buildRewardSection() {
    String status = formatValue(widget.fare['status']);

    switch (status) {
      case 'Approved':
        return _buildApprovedRewardSection();
      case 'pending':
        return _buildPendingRewardSection();
      default:
        return _buildRejectedRewardSection();
    }
  }

  Widget _buildApprovedRewardSection() {
    // Calculate points based on conditions
    int basePoints = 2; // Base points
    int additionalPoints = widget.fare['status'] == 'Approved' ? 3 : 0;
    int pointsEarned = basePoints + additionalPoints;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade200, Colors.yellow.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[800], size: 40),
              const SizedBox(width: 12),
              Text(
                '+$pointsEarned Points Earned!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPointBreakdown(basePoints, additionalPoints),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${widget.fare['helpfulCount'] ?? 47} users found this helpful',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointBreakdown(int basePoints, int additionalPoints) {
    int totalPoints = basePoints + additionalPoints;
    return Column(
      children: [
        _buildPointRow('Base submission', basePoints),
        if (widget.fare['status'] == 'Approved')
          _buildPointRow('Verified submission', additionalPoints),
        const Divider(color: Colors.black26, height: 24),
        _buildPointRow('Total Points', totalPoints, isTotal: true),
      ],
    );
  }

  Widget _buildPointRow(String label, int points, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[700],
                size: isTotal ? 20 : 16,
              ),
              const SizedBox(width: 4),
              Text(
                '+$points',
                style: GoogleFonts.poppins(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRewardSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your submission is being reviewed. You'll earn extra points once approved!",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedRewardSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Submission not approved',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${formatValue(widget.fare['rejectionReason'])}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Don't worry! Keep contributing to help the community.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fare Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFareOverviewCard(),
                _buildRewardSection(),
                _buildJourneyDetailsCard(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareOverviewCard() {
    final status = formatValue(widget.fare['status']);
    final statusColor = {
          'Approved': Colors.green,
          'pending': Colors.orange,
          'Rejected': Colors.red,
        }[status] ??
        Colors.grey;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.yellow.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${formatValue(widget.fare['source'])} → ${formatValue(widget.fare['destination'])}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    color: Colors.green[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  '₦${formatValue(widget.fare['fareAmount'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(
                      DateTime.parse(widget.fare['dateTime'].toString())),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyDetailsCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.yellow.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.yellow[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  'Journey Details',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Route', formatValue(widget.fare['routeTaken']),
                Icons.directions),
            _buildDetailRow('Weather',
                formatValue(widget.fare['weatherConditions']), Icons.cloud),
            _buildDetailRow('Traffic',
                formatValue(widget.fare['trafficConditions']), Icons.traffic),
            _buildDetailRow('Passenger Load',
                formatValue(widget.fare['passengerLoad']), Icons.people),
            _buildDetailRow('Rush Hour',
                formatValue(widget.fare['rushHourStatus']), Icons.schedule),
            _buildDetailRow('Context', formatValue(widget.fare['fareContext']),
                Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.yellow[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
