import 'dart:math';
import 'package:keke_fairshare/index.dart';
import 'package:keke_fairshare/widgets/location_autocomplete_field.dart';
import 'package:keke_fairshare/widgets/landmarks_selector.dart';
import 'package:keke_fairshare/passenger/services/route_query_service.dart';
import 'package:keke_fairshare/passenger/services/user_points_service.dart';

class CheckFareScreen extends StatefulWidget {
  const CheckFareScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CheckFareScreenState createState() => _CheckFareScreenState();
}

class _CheckFareScreenState extends State<CheckFareScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String? _source;
  String? _destination;
  final List<String> _landmarks = [];
  final TextEditingController _landmarkController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  FareFilter? _currentFilter;
  List<Map<String, dynamic>> _matchingRoutes = [];
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreRoutes();
    }
  }

  Future<void> _loadMoreRoutes() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await RouteQueryService.searchRoutes(
        source: _source!,
        destination: _destination!,
        landmarks: _landmarks,
        page: _currentPage + 1,
        filters: _currentFilter?.toMap(),
      );

      setState(() {
        _matchingRoutes.addAll(result.routes);
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more routes: $e')),
      );
    }
  }

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

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
      _matchingRoutes.clear();
    });

    try {
      _formKey.currentState!.save();

      final result = await RouteQueryService.searchRoutes(
        source: _source!,
        destination: _destination!,
        landmarks: _landmarks,
        filters: _currentFilter?.toMap(),
        refresh: true,
      );

      if (result.routes.isEmpty) {
        throw 'No similar routes found with sufficient match (≥80%). Try adjusting your route details.';
      }

      setState(() {
        _matchingRoutes = result.routes;
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
      });

      // Calculate fare statistics
      final fares = _matchingRoutes
          .take(5)
          .map((r) => double.parse(r['fareAmount'].toString()))
          .toList();
      final minFare = fares.reduce((a, b) => a < b ? a : b);
      final maxFare = fares.reduce((a, b) => a > b ? a : b);

      double weightedSum = 0;
      double totalWeight = 0;

      for (var route in _matchingRoutes.take(5)) {
        final weight = route['matchScore'] / 10.0;
        final fare = double.parse(route['fareAmount'].toString());
        weightedSum += fare * weight;
        totalWeight += weight;
      }

      final estimatedFare = weightedSum / totalWeight;
      final confidence = _calculateConfidence(
        _matchingRoutes.take(5).toList(),
        minFare,
        maxFare,
      );

      _showFareResult(
        [minFare.round(), maxFare.round()],
        estimatedFare.round(),
        confidence,
      );
    } catch (e) {
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
                  itemCount: _matchingRoutes.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _matchingRoutes.length) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellow[700]!,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
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
        _currentPage = 0;
        _hasMore = true;
        _matchingRoutes.clear();
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
              controller: _scrollController,
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
