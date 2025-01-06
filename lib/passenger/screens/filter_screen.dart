import 'package:intl/intl.dart';
import 'package:keke_fairshare/index.dart';

class FareFilterScreen extends StatefulWidget {
  final String source; // Your initials for customization
  final String destination; // Your initials for customization
  final List<String> landmarks; // Your initials for customization

  const FareFilterScreen({
    super.key,
    required this.source,
    required this.destination,
    required this.landmarks,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FareFilterScreenState createState() => _FareFilterScreenState();
}

class _FareFilterScreenState extends State<FareFilterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Filter states
  String? _weatherCondition;
  String? _trafficCondition;
  String? _timeOfDay;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  List<Map<String, dynamic>> _fareResults = [];

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Applying filters...");

      Query query = _firestore
          .collection('fares')
          .where('status', isEqualTo: 'Approved')
          .orderBy('submittedAt', descending: true)
          .limit(10);

      if (_weatherCondition != null) {
        print("Filtering by weather condition: $_weatherCondition");
        query = query.where('weatherConditions', isEqualTo: _weatherCondition);
      }
      if (_trafficCondition != null) {
        print("Filtering by traffic condition: $_trafficCondition");
        query = query.where('trafficConditions', isEqualTo: _trafficCondition);
      }
      if (_timeOfDay != null) {
        print("Filtering by time of day: $_timeOfDay");
        query = query.where('rushHourStatus', isEqualTo: _timeOfDay);
      }

      final QuerySnapshot fareSnapshot = await query.get();
      print("Query completed with ${fareSnapshot.docs.length} results");

      setState(() {
        // _fareResults = fareSnapshot.docs
        //     .map((doc) {
        //       final fareData = doc.data() as Map<String, dynamic>;
        //       print("Retrieved fare: $fareData");
        //       return fareData;
        //     })
        _fareResults = fareSnapshot.docs
            .map((doc) {
              final fareData = doc.data() as Map<String, dynamic>;
              fareData['fareAmount'] =
                  (fareData['fareAmount'] as num).toDouble(); // Normalize type
              return fareData;
            })
            //        .where((fare) {
            //   final fareDate = DateTime.parse(fare['submittedAt']);
            //   // Apply date filters as usual
            //   return true;
            // })
            .where((fare) {
              DateTime? fareDate;

              // Parse `submittedAt` as a String to DateTime
              final submittedAt = fare['submittedAt'];
              if (submittedAt is String) {
                try {
                  fareDate = DateTime.parse(submittedAt);
                } catch (e) {
                  print("Error parsing submittedAt as String: $e");
                  return false; // Exclude invalid date formats
                }
              } else {
                print("Unexpected format for submittedAt: $submittedAt");
                return false; // Exclude unexpected formats
              }

              print("Checking fare date: $fareDate");
              if (_startDate != null) {
                print("Comparing start date: $_startDate");
                if (fareDate.isBefore(_startDate!)) {
                  print(
                      "Excluding fare due to start date: ${fare['submittedAt']}");
                  return false;
                }
              }

              if (_endDate != null) {
                // Adjust the end date to cover the entire day
                final adjustedEndDate = _endDate!
                    .add(const Duration(days: 1))
                    .subtract(const Duration(seconds: 1));
                print("Comparing end date: $adjustedEndDate");
                if (fareDate.isAfter(adjustedEndDate)) {
                  print(
                      "Excluding fare due to end date: ${fare['submittedAt']}");
                  return false;
                }
              }

              return true;
            })
            .take(10) // Limit to 10 results
            .toList();
      });

      print("Filtered results: $_fareResults");
    } catch (e) {
      print("Error applying filters: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error applying filters: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print("Filters applied. Loading state: $_isLoading");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Fares',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownFilter(
                    'Weather Condition',
                    ['Sunny', 'Rainy', 'Cloudy'], // Customize as needed
                    _weatherCondition,
                    (value) => setState(() => _weatherCondition = value),
                  ),
                  _buildDropdownFilter(
                    'Traffic Condition',
                    ['Light', 'Moderate', 'Heavy'], // Customize as needed
                    _trafficCondition,
                    (value) => setState(() => _trafficCondition = value),
                  ),
                  _buildDropdownFilter(
                    'Time of Day',
                    [
                      'Morning Rush',
                      'Evening Rush',
                      'Normal Hours'
                    ], // Customize
                    _timeOfDay,
                    (value) => setState(() => _timeOfDay = value),
                  ),
                  _buildDateRangePicker(),
                  const SizedBox(height: 16),
                  if (_fareResults.isNotEmpty) _buildResultsList(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> options,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: value,
        items: [
          DropdownMenuItem(value: null, child: Text('Any')),
          ...options.map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range'),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_startDate == null
                    ? 'Start Date'
                    : DateFormat('MMM d, y').format(_startDate!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate == null
                    ? 'End Date'
                    : DateFormat('MMM d, y').format(_endDate!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    final average = _fareResults.isEmpty
        ? 0.0
        : _fareResults
                .map((f) =>
                    (f['fareAmount'] as num).toDouble()) // Use num for safety
                .reduce((a, b) => a + b) /
            _fareResults.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtered Results:',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...(_fareResults.map((fare) => ListTile(
              title: Text(
                'Source: ${fare['source']} → Destination: ${fare['destination']}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fare: ₦${(fare['fareAmount'] as num).toDouble().toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${fare['weatherConditions']} • ${fare['trafficConditions']} • ${DateFormat('MMM d, y').format(DateTime.parse(fare['submittedAt']))}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ))),
        const Divider(),
        ListTile(
          title: Text('Average Fare: ₦${average.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          subtitle: Text('Based on ${_fareResults.length} fares',
              style: GoogleFonts.poppins()),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Apply Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
