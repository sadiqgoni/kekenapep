import 'dart:math';
import 'package:keke_fairshare/index.dart';
import 'package:keke_fairshare/widgets/location_autocomplete_field.dart';
import 'package:keke_fairshare/widgets/landmarks_selector.dart';

class CheckFareScreen extends StatefulWidget {
  const CheckFareScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CheckFareScreenState createState() => _CheckFareScreenState();
}

class _CheckFareScreenState extends State<CheckFareScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _source;
  String? _destination;
  final List<String> _landmarks = [];
  final TextEditingController _landmarkController = TextEditingController();
  bool _isLoading = false;
  FareFilter? _currentFilter;
  List<Map<String, dynamic>> _matchingRoutes = [];

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
    if (!(_formKey.currentState?.validate() ?? false) ||
        _landmarks.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter source, destination, and at least 2 landmarks.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      _formKey.currentState!.save();

      // Step 1: Get Approved routes within the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final sourceDestQuery = await _firestore
          .collection('fares')
          .where('status', isEqualTo: 'Approved')
          .where('submittedAt', isGreaterThan: thirtyDaysAgo.toIso8601String())
          .get();

      // Step 2: Score and filter matches
      List<Map<String, dynamic>> potentialMatches = [];

      for (var doc in sourceDestQuery.docs) {
        final data = doc.data();

        // Initialize match score
        double matchScore = 0;
        double maxPossibleScore = 0;

        // Source/destination scoring (max 20 points)
        maxPossibleScore += 20;
        if (_isExactMatch(data['source'], _source!)) {
          matchScore += 10; // Increased from 5
        } else if (_isFuzzyMatch(data['source'], _source!)) {
          matchScore += 5; // Increased from 3
        }

        if (_isExactMatch(data['destination'], _destination!)) {
          matchScore += 10; // Increased from 5
        } else if (_isFuzzyMatch(data['destination'], _destination!)) {
          matchScore += 5; // Increased from 3
        }

        // Landmark scoring (max 30 points - 10 per landmark)
        List<String> routeLandmarks =
            List<String>.from(data['routeTaken'] ?? []);
        int landmarkMatches = 0;
        double landmarkScore = 0;

        for (String landmark in _landmarks) {
          maxPossibleScore += 10;
          double bestMatchForLandmark = 0;

          for (String routeLandmark in routeLandmarks) {
            if (_isExactMatch(landmark, routeLandmark)) {
              bestMatchForLandmark = 10; // Increased from 3
              landmarkMatches++;
              break;
            } else {
              double similarity = _calculateLevenshteinSimilarity(
                  landmark.toLowerCase(), routeLandmark.toLowerCase());
              bestMatchForLandmark = max(bestMatchForLandmark,
                  similarity * 8); // Up to 8 points for close matches
            }
          }
          landmarkScore += bestMatchForLandmark;
        }
        matchScore += landmarkScore;

        // Time-based relevance (reduce score by up to 20% based on age)
        final submissionDate = DateTime.parse(data['submittedAt']);
        final daysAgo = DateTime.now().difference(submissionDate).inDays;
        double timeMultiplier = 1.0 - (daysAgo / 30) * 0.2;
        matchScore *= timeMultiplier;

        // Calculate percentage match
        double matchPercentage = (matchScore / maxPossibleScore) * 100;

        // Only include if match percentage is >= 80% and has at least one landmark match
        if (matchPercentage >= 80 && landmarkMatches >= 1) {
          potentialMatches.add({
            ...data,
            'id': doc.id,
            'matchScore': matchPercentage,
            'submitterUid': data['submitter']?['uid'] ?? '',
          });
        }
      }

      // await AppLogger.logInfo(
      //   'CheckFare',
      //   'Match scoring complete',
      //   additionalInfo: {
      //     'potentialMatchesCount': potentialMatches.length,
      //   },
      // );

      // Step 3: Process matches and calculate fare
      if (potentialMatches.isEmpty) {
        throw 'No similar routes found with sufficient match (≥80%). Try adjusting your route details.';
      }

      // Get user points for each submitter
      final submitterIds = potentialMatches
          .map((m) => m['submitterUid'] as String)
          .toSet()
          .toList();
      final userStatsSnapshots = await Future.wait(submitterIds.map((uid) =>
          _firestore
              .collection('users')
              .doc(uid)
              .collection('statistics')
              .doc('overview')
              .get()));

      // Create map of user points
      final userPoints = Map.fromIterables(
          submitterIds,
          userStatsSnapshots.map(
              (snap) => (snap.data()?['points'] as num?)?.toDouble() ?? 0.0));

      // Sort by match score and user points (weighted combination)
      potentialMatches.sort((a, b) {
        final scoreA = a['matchScore'] as double;
        final scoreB = b['matchScore'] as double;
        final pointsA = userPoints[a['submitterUid']] ?? 0.0;
        final pointsB = userPoints[b['submitterUid']] ?? 0.0;

        // Normalize points to 0-100 range for fair comparison with match score
        final maxPoints = userPoints.values.reduce(max);
        final normalizedPointsA = (pointsA / maxPoints) * 100;
        final normalizedPointsB = (pointsB / maxPoints) * 100;

        // Weight: 70% match score, 30% user points
        final weightedScoreA = (scoreA * 0.7) + (normalizedPointsA * 0.3);
        final weightedScoreB = (scoreB * 0.7) + (normalizedPointsB * 0.3);

        return weightedScoreB.compareTo(weightedScoreA);
      });

      // Calculate weighted average fare
      double totalWeight = 0;
      double weightedFareSum = 0;
      List<double> fares = [];

      for (var match in potentialMatches.take(5)) {
        double weight = match['matchScore'] / 10.0;
        double fare = double.parse(match['fareAmount'].toString());

        weightedFareSum += fare * weight;
        totalWeight += weight;
        fares.add(fare);
      }

      double estimatedFare = weightedFareSum / totalWeight;
      double minFare = fares.reduce(min);
      double maxFare = fares.reduce(max);

      // Calculate confidence
      String confidence = _calculateConfidence(
        potentialMatches.take(5).toList(),
        minFare,
        maxFare,
      );

      // await AppLogger.logInfo(
      //   'CheckFare',
      //   'Fare calculation complete',
      //   additionalInfo: {
      //     'estimatedFare': estimatedFare,
      //     'minFare': minFare,
      //     'maxFare': maxFare,
      //     'confidence': confidence,
      //   },
      // );

      setState(() {
        _matchingRoutes = potentialMatches;
      });

      if (_currentFilter != null) {
        _matchingRoutes = _matchingRoutes.where((route) {
          final routeDate = DateTime.parse(route['dateTime']);

          if (_currentFilter!.fromDate != null &&
              routeDate.isBefore(_currentFilter!.fromDate!)) {
            return false;
          }

          if (_currentFilter!.weatherCondition != null &&
              route['weatherConditions'] != _currentFilter!.weatherCondition) {
            return false;
          }

          if (_currentFilter!.trafficCondition != null &&
              route['trafficConditions'] != _currentFilter!.trafficCondition) {
            return false;
          }

          if (_currentFilter!.passengerLoad != null &&
              route['passengerLoad'] != _currentFilter!.passengerLoad) {
            return false;
          }

          if (_currentFilter!.rushHourStatus != null &&
              route['rushHourStatus'] != _currentFilter!.rushHourStatus) {
            return false;
          }

          return true;
        }).toList();
      }

      _showFareResult(
        [minFare.round(), maxFare.round()],
        estimatedFare.round(),
        confidence,
      );
    } catch (e) {
      // await AppLogger.logError(
      //   'CheckFare',
      //   'Error generating fare',
      //   additionalInfo: {'error': e.toString()},
      // );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isExactMatch(String str1, String str2) {
    str1 = str1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    str2 = str2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // Check for exact match
    if (str1 == str2) return true;

    // Check for match with common variations
    final variations1 = _getCommonVariations(str1);
    final variations2 = _getCommonVariations(str2);

    return variations1.any((v1) => variations2.contains(v1));
  }

  bool _isFuzzyMatch(String str1, String str2) {
    str1 = str1.toLowerCase().trim();
    str2 = str2.toLowerCase().trim();

    // Check if one string contains the other
    if (str1.contains(str2) || str2.contains(str1)) {
      return true;
    }

    // Calculate similarity
    double similarity = _calculateLevenshteinSimilarity(str1, str2);

    // More lenient threshold for longer strings
    double threshold = str1.length > 10 || str2.length > 10 ? 0.7 : 0.8;

    return similarity > threshold;
  }

  String _calculateConfidence(
      List<Map<String, dynamic>> topMatches, double minFare, double maxFare) {
    // Calculate confidence based on:
    // 1. Number of good matches
    // 2. Fare range spread
    // 3. Match scores

    double fareSpread = (maxFare - minFare) / maxFare;
    double avgMatchScore =
        topMatches.map((m) => m['matchScore']).reduce((a, b) => a + b) /
            topMatches.length;

    if (topMatches.length >= 4 && fareSpread < 0.2 && avgMatchScore > 6) {
      return 'High';
    } else if (topMatches.length >= 3 &&
        fareSpread < 0.3 &&
        avgMatchScore > 4) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  void _showFareResult(List<int> fares, int average, String confidence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Estimated Fare',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.yellow[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '₦$average',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow[900],
                        ),
                      ),
                      Text(
                        'Range: ₦${fares[0]} - ₦${fares[1]}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      // const SizedBox(height: 8),
                      _buildWarningIndicator(confidence),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Similar Routes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    label: const Text('Filter',
                        style: TextStyle(color: Colors.black)),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _matchingRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _matchingRoutes[index];
                    return RouteMatchCard(
                      route: route,
                      matchScore: route['matchScore'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() async {
    final result = await showDialog<FareFilter>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: FilterDialog(currentFilter: _currentFilter),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
      _generateFare();
    }
  }

  Widget _buildWarningIndicator(String confidence) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 10,
          color: Colors.red,
        ),
        const SizedBox(width: 12),
        Text(
          'Note: This is not actual fare price, always negotiate with driver!',
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  double _calculateLevenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty) return s2.isEmpty ? 1.0 : 0.0;
    if (s2.isEmpty) return 0.0;

    // Convert to lowercase for case-insensitive comparison
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // Fill in the rest of the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    // Calculate similarity as a value between 0 and 1
    int maxLength = max(s1.length, s2.length);
    return 1 - (matrix[s1.length][s2.length] / maxLength);
  }

  Set<String> _getCommonVariations(String text) {
    final Set<String> variations = {text};

    // Add common abbreviations and variations
    variations.add(text.replaceAll('road', 'rd'));
    variations.add(text.replaceAll('rd', 'road'));
    variations.add(text.replaceAll('street', 'st'));
    variations.add(text.replaceAll('st', 'street'));
    variations.add(text.replaceAll('junction', 'jcn'));
    variations.add(text.replaceAll('jcn', 'junction'));

    // Remove special characters
    variations.add(text.replaceAll(RegExp(r'[^\w\s]'), ''));

    return variations;
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
                    LocationAutocompleteField(
                      label: 'Source',
                      icon: Icons.location_on,
                      onSelected: (value) => _source = value,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter source' : null,
                    ),
                    const SizedBox(height: 16),
                    LocationAutocompleteField(
                      label: 'Destination',
                      icon: Icons.location_searching,
                      onSelected: (value) => _destination = value,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter destination'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Landmarks (at least 2)'),
                    LandmarksSelector(
                      source: _source ?? '',
                      destination: _destination ?? '',
                      selectedLandmarks: _landmarks,
                      onLandmarksChanged: (landmarks) {
                        setState(() => _landmarks.clear());
                        setState(() => _landmarks.addAll(landmarks));
                      },
                    ),
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
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.yellow[700],
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
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
}
