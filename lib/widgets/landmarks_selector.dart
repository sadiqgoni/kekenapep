import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LandmarksSelector extends StatefulWidget {
  final String source;
  final String destination;
  final List<String> selectedLandmarks;
  final Function(List<String>) onLandmarksChanged;

  const LandmarksSelector({
    super.key,
    required this.source,
    required this.destination,
    required this.selectedLandmarks,
    required this.onLandmarksChanged,
  });

  @override
  State<LandmarksSelector> createState() => _LandmarksSelectorState();
}

class _LandmarksSelectorState extends State<LandmarksSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _suggestedLandmarks = [];
  List<String> _filteredSuggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedLandmarks();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void didUpdateWidget(LandmarksSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.destination != widget.destination) {
      _loadSuggestedLandmarks();
    }
  }

  Future<void> _loadSuggestedLandmarks() async {
    if (widget.source.isEmpty || widget.destination.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Query routes between source and destination
      final routes = await _firestore
          .collection('fares')
          .where('source', isEqualTo: widget.source.toLowerCase())
          .where('destination', isEqualTo: widget.destination.toLowerCase())
          .where('status', isEqualTo: 'Approved')
          .get();

      // Extract and deduplicate landmarks
      final Set<String> landmarks = {};
      for (var doc in routes.docs) {
        final routeLandmarks = List<String>.from(doc['routeTaken'] ?? []);
        landmarks.addAll(routeLandmarks);
      }

      setState(() {
        _suggestedLandmarks = landmarks.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _filteredSuggestions = _suggestedLandmarks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading suggested landmarks: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = _suggestedLandmarks;
        _showSuggestions = true;
      });
      return;
    }

    setState(() {
      _filteredSuggestions = _suggestedLandmarks
          .where((landmark) =>
              landmark.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSuggestions = true;
    });
  }

  void _addLandmark(String landmark) {
    if (landmark.isNotEmpty && !widget.selectedLandmarks.contains(landmark)) {
      final updatedLandmarks = [...widget.selectedLandmarks, landmark];
      widget.onLandmarksChanged(updatedLandmarks);
      _controller.clear();
      setState(() => _showSuggestions = false);
    }
  }

  void _removeLandmark(int index) {
    final updatedLandmarks = [...widget.selectedLandmarks];
    updatedLandmarks.removeAt(index);
    widget.onLandmarksChanged(updatedLandmarks);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suggestedLandmarks.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Landmarks on this Route:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedLandmarks
                    .where((landmark) =>
                        !widget.selectedLandmarks.contains(landmark))
                    .map((landmark) => ActionChip(
                          label: Text(
                            landmark,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[100],
                          onPressed: () => _addLandmark(landmark),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Or Add Custom Landmark:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _filterSuggestions,
          decoration: InputDecoration(
            labelText: 'Enter Landmark',
            hintText: 'e.g. Kofar Nassarawa, Zoo Road',
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Colors.yellow[700]),
              onPressed: () => _addLandmark(_controller.text.trim()),
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
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                if (widget.selectedLandmarks.contains(suggestion)) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestion,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  onTap: () => _addLandmark(suggestion),
                );
              },
            ),
          ),
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[700]!),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (widget.selectedLandmarks.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Landmarks:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(
                  widget.selectedLandmarks.length,
                  (index) => Chip(
                    label: Text(
                      widget.selectedLandmarks[index],
                      style: GoogleFonts.poppins(),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeLandmark(index),
                    backgroundColor: Colors.yellow[100],
                    deleteIconColor: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
