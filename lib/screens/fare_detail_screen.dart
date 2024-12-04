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
      case 'Pending':
        return _buildPendingRewardSection();
      default:
        return _buildRejectedRewardSection();
    }
  }

  Widget _buildApprovedRewardSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade200, Colors.yellow.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                '+1 Point Earned!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for helping the community! Your fare submission has been verified and approved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '47 users found this helpful',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your submission is being reviewed. You'll earn points once approved!",
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatValue(widget.fare['source'])} to ${formatValue(widget.fare['destination'])}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Fare Amount: ₦${formatValue(widget.fare['fareAmount'])}',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted on ${DateFormat('MMM d, yyyy').format(DateTime.parse(widget.fare['dateTime'].toString()))}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Details',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Route', formatValue(widget.fare['routeTaken'])),
            _buildDetailRow(
                'Weather', formatValue(widget.fare['weatherConditions'])),
            _buildDetailRow(
                'Traffic', formatValue(widget.fare['trafficConditions'])),
            _buildDetailRow(
                'Passenger Load', formatValue(widget.fare['passengerLoad'])),
            _buildDetailRow('Context', formatValue(widget.fare['fareContext'])),
            _buildDetailRow(
                'Rush Hour', formatValue(widget.fare['rushHourStatus'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
