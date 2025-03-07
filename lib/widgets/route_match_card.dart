import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RouteMatchCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final double matchScore;

  const RouteMatchCard({
    super.key,
    required this.route,
    required this.matchScore,
  });

  @override
  State<RouteMatchCard> createState() => _RouteMatchCardState();
}

class _RouteMatchCardState extends State<RouteMatchCard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLiked = false;
  bool _isLoading = false;
  int _helpfulCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHelpfulStatus();
  }

  Future<void> _loadHelpfulStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get the helpful count
      final fareDoc =
          await _firestore.collection('fares').doc(widget.route['id']).get();
      setState(() {
        _helpfulCount = (fareDoc.data()?['helpfulCount'] ?? 0) as int;
      });

      // Check if user has already marked this as helpful
      final userHelpfulDoc = await _firestore
          .collection('fares')
          .doc(widget.route['id'])
          .collection('helpful')
          .doc(userId)
          .get();

      setState(() {
        _isLiked = userHelpfulDoc.exists;
      });
    } catch (e) {
      print('Error loading helpful status: $e');
    }
  }

  Future<void> _toggleHelpful() async {
    if (_isLoading) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please sign in to mark routes as helpful')),
      );
      return;
    }

    // Check if we have a valid document ID
    final String? fareId = widget.route['id'];
    if (fareId == null || fareId.isEmpty) {
      print('Error: Invalid or missing fare ID in route data: ${widget.route}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot mark as helpful: Invalid route reference')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting to toggle helpful status for fare ID: $fareId');
      final userHelpfulRef = _firestore
          .collection('fares')
          .doc(fareId)
          .collection('helpful')
          .doc(userId);

      final userHelpfulDoc = await userHelpfulRef.get();
      print('Current helpful status exists: ${userHelpfulDoc.exists}');

      if (userHelpfulDoc.exists) {
        // Remove helpful mark
        await userHelpfulRef.delete();
        setState(() {
          _isLiked = false;
          _helpfulCount--;
        });
        print('Successfully removed helpful mark');
      } else {
        // Add helpful mark
        await userHelpfulRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId, // Add user ID for reference
          'fareId': fareId // Add fare ID for reference
        });
        setState(() {
          _isLiked = true;
          _helpfulCount++;
        });
        print('Successfully added helpful mark');
      }
    } catch (e) {
      print('Error toggling helpful status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating helpful status: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.yellow[50],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.yellow[100]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₦${widget.route['fareAmount'].toString()}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Row(
                  children: [
                    if (widget.route['submitterUid'] != null)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.route['submitterUid'])
                            .collection('statistics')
                            .doc('overview')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data?.data() != null) {
                            final points = (snapshot.data!.data()
                                    as Map<String, dynamic>)['points'] ??
                                0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.stars,
                                      size: 12, color: Colors.blue[900]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$points pts',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Match: ${widget.matchScore.round()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.yellow[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.route['source']} → ${widget.route['destination']}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Via: ${(widget.route['routeTaken'] as List).join(' → ')}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildInfoChip(Icons.people, widget.route['passengerLoad']),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                        Icons.cloud, widget.route['weatherConditions']),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                        Icons.traffic, widget.route['trafficConditions']),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$_helpfulCount helpful',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 16,
                      ),
                      color: _isLiked ? Colors.blue[700] : Colors.grey[600],
                      onPressed: _isLoading ? null : _toggleHelpful,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy - HH:mm').format(
                DateTime.parse(widget.route['dateTime']),
              ),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
