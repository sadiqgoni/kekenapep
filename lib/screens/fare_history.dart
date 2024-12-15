import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fare_detail_screen.dart'; // Import the FareDetailScreen

class FareHistoryScreen extends StatelessWidget {
  const FareHistoryScreen({super.key});

  Stream<QuerySnapshot> getFareHistoryStream() {
    return FirebaseFirestore.instance
        .collection('fares')
        .orderBy('submittedAt', descending: true) // Sort by submission date
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fare History',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getFareHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No fare history available.',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[600])),
            );
          }

          final fares = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: fares.length,
            itemBuilder: (context, index) {
              final fareDocument = fares[index]; // Pass the DocumentSnapshot
              return _buildFareHistoryCard(context, fareDocument);
            },
          );
        },
      ),
    );
  }

  Widget _buildFareHistoryCard(
      BuildContext context, DocumentSnapshot fareDocument) {
    final fare = fareDocument.data() as Map<String, dynamic>;

    String? rejectionReason =
        fare['status'] == 'Rejected' ? fare['rejectionReason'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    '${fare['source']} to ${fare['destination']}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(fare['status']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare: ₦${fare['fareAmount']}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('MMM d, yyyy')
                      .format(DateTime.parse(fare['dateTime'])),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            if (rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason: $rejectionReason',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FareDetailScreen(fare: fare),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                  ),
                ),
                if (fare['status'] != 'Approved') ...[
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteFare(context, fareDocument);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFare(BuildContext context, DocumentSnapshot fareDocument) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellow[50],
        titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, color: Colors.black),
        title: Text('Delete Fare', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to delete this fare?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('User not logged in');
                }

                final firestore = FirebaseFirestore.instance;
                await firestore.runTransaction((transaction) async {
                  // Get user stats document
                  final statsRef = firestore
                      .collection('users')
                      .doc(userId)
                      .collection('statistics')
                      .doc('overview');

                  final statsDoc = await transaction.get(statsRef);
                  if (!statsDoc.exists) {
                    throw Exception('User stats not found');
                  }

                  // Update user stats
                  final currentPoints = statsDoc.data()?['points'] ?? 0;
                  final currentSubmissions =
                      statsDoc.data()?['totalSubmissions'] ?? 0;

                  transaction.update(statsRef, {
                    'points': currentPoints - 2, // Subtract 2 points
                    'totalSubmissions':
                        currentSubmissions - 1, // Decrement submissions
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  // Delete the fare document
                  transaction.delete(fareDocument.reference);
                });

                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Fare deleted successfully',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting fare: ${e.toString()}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.black)),
          ),
        ],
      ),
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
      case 'Pending':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
            color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
