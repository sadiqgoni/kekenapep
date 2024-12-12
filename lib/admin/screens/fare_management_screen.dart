// ignore_for_file: unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FareManagementPage extends StatefulWidget {
  const FareManagementPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FareManagementPageState createState() => _FareManagementPageState();
}

class _FareManagementPageState extends State<FareManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String _selectedFilter = 'Pending'; // Default filter
  bool _isLoading = false;
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Pending';
    // updateFareStatusToPending();
  }

  Future<void> updateFareStatusToPending() async {
    try {
      // Fetch the existing fare documents from Firestore
      final fares = await FirebaseFirestore.instance.collection('fares').get();

      // Loop through each document in the 'fares' collection
      for (var fare in fares.docs) {
        final status = fare['status']; // Get the current status field value

        // Update the status field to 'pending' for each fare document
        await fare.reference.update({
          'status': 'pending', // Update status to 'pending'
        });

        // print('Updated status to pending for fare with ID: ${fare.id}');
      }

      // Optionally, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fare statuses updated to pending.',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating fare status: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fare Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['All', 'Pending', 'Approved', 'Rejected']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins()),
                    ))
                .toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildFaresList(),
    );
  }

  Widget _buildFaresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: GoogleFonts.poppins()));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('No fare submissions available.',
                  style: GoogleFonts.poppins()));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildFareSubmissionCard(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = _firestore.collection('fares');

    // Apply status filter only if it's not 'All'
    if (_selectedFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.orderBy('submittedAt', descending: true).limit(50).snapshots();
  }

  Widget _buildFareSubmissionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime submittedAt = DateTime.parse(data['submittedAt']);
    final String formattedDate =
        DateFormat('MMM d, y HH:mm').format(submittedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          '${data['source']} → ${data['destination']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fare: ₦${data['fareAmount']}', style: GoogleFonts.poppins()),
            Text('Submitted: $formattedDate', style: GoogleFonts.poppins()),
            Row(
              children: [
                Text('Status: ', style: GoogleFonts.poppins()),
                _buildStatusChip(data['status'] ?? 'Pending'),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Weather', data['weatherConditions']),
                _buildDetailItem('Traffic', data['trafficConditions']),
                _buildDetailItem('Passenger Load', data['passengerLoad']),
                _buildDetailItem('Rush Hour Status', data['rushHourStatus']),
                if (data['routeTaken']?.isNotEmpty ?? false)
                  _buildDetailItem(
                      'Route Taken', (data['routeTaken'] as List).join(' → ')),
                if (data['fareContext']?.isNotEmpty ?? false)
                  _buildDetailItem('Context', data['fareContext']),
                if (data['rejectionReason']?.isNotEmpty ?? false)
                  _buildDetailItem('Rejection Reason', data['rejectionReason'],
                      isRejection: true),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Approve',
                      Colors.green,
                      () => _updateFareStatus(doc.id, 'Approved'),
                      data['status'] == 'Approved',
                    ),
                    _buildActionButton(
                      'Reject',
                      Colors.red,
                      () => _showRejectionDialog(doc.id),
                      data['status'] == 'Rejected',
                    ),
                    _buildActionButton(
                      'Flag',
                      Colors.orange,
                      () => _updateFareStatus(doc.id, 'Flagged'),
                      data['status'] == 'Flagged',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value,
      {bool isRejection = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: isRejection ? Colors.red : null)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, Color color, VoidCallback onPressed, bool isActive) {
    return ElevatedButton(
      onPressed: isActive ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey,
      ),
      child: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      case 'Flagged':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Chip(
      label: Text(status, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: statusColor,
    );
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
              _updateFareStatus(fareId, 'Rejected',
                  reason: _rejectionReasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Reject', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFareStatus(String fareId, String status,
      {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      // Update main fare document
      final fareRef = _firestore.collection('fares').doc(fareId);
      final fareDoc = await fareRef.get();
      final data = fareDoc.data() as Map<String, dynamic>;

      await fareRef.update({
        'status': status,
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': 'admin', // You might want to use actual admin ID
        if (reason != null) 'rejectionReason': reason,
      });

      // Update user's submission copy
      if (data['userId'] != null) {
        await _firestore
            .collection('users')
            .doc(data['userId'])
            .collection('submissions')
            .doc(fareId)
            .update({
          'status': status,
          'reviewedAt': DateTime.now().toIso8601String(),
          'reviewedBy': 'admin',
          if (reason != null) 'rejectionReason': reason,
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Fare $status successfully', style: GoogleFonts.poppins()),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error updating fare: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
