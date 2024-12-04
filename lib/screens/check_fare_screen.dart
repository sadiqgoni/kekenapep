import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keke_fairshare/screens/filter_screen.dart';

class CheckFareScreen extends StatefulWidget {
  const CheckFareScreen({Key? key}) : super(key: key);

  @override
  _CheckFareScreenState createState() => _CheckFareScreenState();
}

class _CheckFareScreenState extends State<CheckFareScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _source;
  String? _destination;
  List<String> _landmarks = [];
  final TextEditingController _landmarkController = TextEditingController();
  bool _isLoading = false;

  void _addLandmark() {
    if (_landmarkController.text.isNotEmpty) {
      setState(() {
        _landmarks.add(_landmarkController.text.trim().toLowerCase());
        _landmarkController.clear();
      });
    }
  }

  void _removeLandmark(int index) {
    setState(() {
      _landmarks.removeAt(index);
    });
  }

  Future<void> _generateFare() async {
    if (_formKey.currentState!.validate() && _landmarks.length >= 3) {
      // final fares = await FirebaseFirestore.instance.collection('fares').get();
      // for (var fare in fares.docs) {
      //   final fareAmount = fare['fareAmount'];
      //   if (fareAmount is int) {
      //     await fare.reference.update({'fareAmount': fareAmount.toDouble()});
      //     print('Done');
      //   }
      //}

      _formKey.currentState!.save();

      setState(() => _isLoading = true);
      try {
        // First, validate that we have all required data
        if (_source == null || _destination == null || _landmarks.isEmpty) {
          throw 'Please enter all required route information';
        }

        final QuerySnapshot fareSnapshot = await _firestore
            .collection('fares')
            .where('status', isEqualTo: 'Approved')
            .orderBy('submittedAt', descending: true)
            .limit(50)
            .get();

        if (fareSnapshot.docs.isEmpty) {
          throw 'No fare data available';
        }

        List<Map<String, dynamic>> matchingFares = [];

        // Safer data extraction with null checking
        for (var doc in fareSnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // Validate required fields exist
            if (!data.containsKey('source') ||
                !data.containsKey('destination') ||
                !data.containsKey('routeTaken') ||
                !data.containsKey('fareAmount')) {
              continue; // Skip invalid entries
            }

            final double similarity = _calculateRouteSimilarity(
              data['source']?.toString().toLowerCase() ?? '',
              data['destination']?.toString().toLowerCase() ?? '',
              List<String>.from(data['routeTaken'] ?? []),
              _source!.toLowerCase(),
              _destination!.toLowerCase(),
              _landmarks,
            );

            // Only include if similarity is above threshold
            if (similarity > 0.3) {
              matchingFares.add({
                'source': data['source'],
                'destination': data['destination'],
                'routeTaken': data['routeTaken'],
                'fareAmount': data['fareAmount'],
                'submittedAt': data['submittedAt'],
                'similarity': similarity,
              });
            }
          } catch (e) {
            print('Error processing fare document: $e');
            continue; // Skip problematic documents
          }
        }

        // Sort by similarity
        matchingFares
            .sort((a, b) => b['similarity'].compareTo(a['similarity']));
        matchingFares = matchingFares.take(10).toList();

        if (matchingFares.isEmpty) {
          throw 'No similar routes found. Try adjusting your landmarks or route.';
        }

        // Safe fare calculation
        List<double> fares = [];
        for (var fare in matchingFares) {
          try {
            double fareAmount = fare['fareAmount'] is int
                ? fare['fareAmount']
                : double.parse(fare['fareAmount'].toString());
            fares.add(fareAmount);
          } catch (e) {
            print('Error parsing fare amount: $e');
            continue;
          }
        }

        if (fares.isEmpty) {
          throw 'Unable to calculate fares from matching routes';
        }

        // Calculate average with validated fares
        double mean = fares.reduce((a, b) => a + b) / fares.length;

        // Only calculate standard deviation if we have enough fares
        if (fares.length > 1) {
          double stdDev = sqrt(
              fares.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
                  fares.length);

          // Remove outliers
          fares = fares.where((x) => (x - mean).abs() <= 2 * stdDev).toList();
        }

        // Recalculate average without outliers
        double average =
            fares.isEmpty ? mean : fares.reduce((a, b) => a + b) / fares.length;

        String confidence = _calculateConfidenceLevel(matchingFares);

        // Debug logging
        print('Found ${matchingFares.length} matching fares');
        print('Calculated average: $average');
        print('Confidence level: $confidence');

        _showFareResult(fares.map((fare) => fare.round()).toList(),
            average.round(), confidence);
      } catch (e) {
        print('Error in _generateFare: $e'); // Debug logging

        String errorMessage = e.toString();
        if (!errorMessage.contains('No similar routes') &&
            !errorMessage.contains('Please enter') &&
            !errorMessage.contains('Unable to calculate')) {
          errorMessage =
              'Error calculating fare: ${e.toString()}\nPlease try adjusting your route or landmarks.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter source, destination, and at least 3 landmarks.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper function to calculate confidence level with better accuracy
  String _calculateConfidenceLevel(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) return 'Low';

    double highestSimilarity = matches.first['similarity'] as double;
    int matchCount = matches.length;

    if (matchCount >= 8 && highestSimilarity > 0.7) {
      return 'High';
    } else if (matchCount >= 5 && highestSimilarity > 0.5) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

// Improved route similarity calculation with better error handling
  double _calculateRouteSimilarity(
    String source1,
    String dest1,
    List<String> route1,
    String source2,
    String dest2,
    List<String> route2,
  ) {
    try {
      double score = 0.0;

      // Validate inputs
      if (source1.isEmpty ||
          dest1.isEmpty ||
          source2.isEmpty ||
          dest2.isEmpty) {
        return 0.0;
      }

      // Source and destination matching
      double sourceSimScore = _calculateLevenshteinSimilarity(source1, source2);
      double destSimScore = _calculateLevenshteinSimilarity(dest1, dest2);

      score += sourceSimScore * 0.3;
      score += destSimScore * 0.3;

      // Landmark matching with validation
      if (route1.isNotEmpty && route2.isNotEmpty) {
        final route1Lower = route1.map((e) => e.toLowerCase()).toList();
        final route2Lower = route2.map((e) => e.toLowerCase()).toList();

        int matchedLandmarks = 0;
        for (final landmark in route2Lower) {
          if (landmark.isEmpty) continue;

          double bestMatch = 0.0;
          for (final routeLandmark in route1Lower) {
            if (routeLandmark.isEmpty) continue;

            double similarity =
                _calculateLevenshteinSimilarity(landmark, routeLandmark);
            bestMatch = max(bestMatch, similarity);
          }
          if (bestMatch > 0.7) {
            matchedLandmarks++;
          }
        }

        if (route2Lower.isNotEmpty) {
          score += (matchedLandmarks / route2Lower.length) * 0.4;
        }
      }
      print(
          'Source similarity: $sourceSimScore, Destination similarity: $destSimScore, Route similarity: $score');

      return score;
    } catch (e) {
      print('Error calculating route similarity: $e');
      return 0.0; // Return minimum score on error
    }
  }

// Helper function to calculate string similarity
  double _calculateLevenshteinSimilarity(String s1, String s2) {
    int distance = _levenshteinDistance(s1, s2);
    int maxLength = max(s1.length, s2.length);
    return maxLength == 0 ? 1.0 : 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[s1.length][s2.length];
  }

// Show results with improved UI
  void _showFareResult(List<int> fares, int average, String confidence) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Fare Estimate',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route Details:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text('From: $_source', style: GoogleFonts.poppins()),
                Text('To: $_destination', style: GoogleFonts.poppins()),
                const SizedBox(height: 16),
                Text(
                  'Estimated Fare Range:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₦${fares.reduce(min)} - ₦${fares.reduce(max)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recommended Fare:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₦$average',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: confidence == 'High'
                          ? Colors.green
                          : confidence == 'Medium'
                              ? Colors.orange
                              : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: $confidence',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: confidence == 'High'
                            ? Colors.green
                            : confidence == 'Medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Based on ${fares.length} recent similar trips',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Apply Filters',
                  style: GoogleFonts.poppins(color: Colors.blue)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FareFilterScreen(
                      source: _source!,
                      destination: _destination!,
                      landmarks: _landmarks,
                    ),
                  ),
                );
              },
            ),
            TextButton(
              child: Text('Close',
                  style: GoogleFonts.poppins(color: Colors.yellow[700])),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Fare',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Route Information'),
                    _buildTextField(
                      label: 'Source',
                      onSaved: (value) => _source = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter source' : null,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Destination',
                      onSaved: (value) => _destination = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter destination' : null,
                      icon: Icons.location_searching,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Landmarks (at least 3)'),
                    _buildLandmarkInput(),
                    const SizedBox(height: 16),
                    _buildLandmarkChips(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateFare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Text(
                                'Generate Fare',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType? keyboardType,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    required IconData icon,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.yellow[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildLandmarkInput() {
    return TextFormField(
      controller: _landmarkController,
      decoration: InputDecoration(
        labelText: 'Enter Landmark',
        hintText: 'e.g. Kofar Nassarawa, Zoo Road',
        suffixIcon: IconButton(
          icon: Icon(Icons.add, color: Colors.yellow[700]),
          onPressed: _addLandmark,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildLandmarkChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List<Widget>.generate(
        _landmarks.length,
        (index) => Chip(
          label: Text(_landmarks[index], style: GoogleFonts.poppins()),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeLandmark(index),
          backgroundColor: Colors.yellow[100],
          deleteIconColor: Colors.red[700],
        ),
      ),
    );
  }
}
