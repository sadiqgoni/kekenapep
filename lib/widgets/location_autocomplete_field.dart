import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function(String) onSelected;
  final String? Function(String?)? validator;
  final bool enabled;

  const LocationAutocompleteField({
    super.key,
    required this.label,
    required this.icon,
    required this.onSelected,
    this.validator,
    this.enabled = true,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Query both source and destination fields from fares collection
      final sourceQuery = await _firestore
          .collection('fares')
          .where('source', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('source', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      final destQuery = await _firestore
          .collection('fares')
          .where('destination', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('destination',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      // Combine and deduplicate results
      final Set<String> locations = {};
      for (var doc in sourceQuery.docs) {
        locations.add(doc['source'] as String);
      }
      for (var doc in destQuery.docs) {
        locations.add(doc['destination'] as String);
      }

      setState(() {
        _suggestions = locations.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _showSuggestions = _suggestions.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location suggestions: $e');
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          enabled: widget.enabled,
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) {
            if (value.length >= 2) {
              _getSuggestions(value);
            } else {
              setState(() {
                _suggestions = [];
                _showSuggestions = false;
              });
            }
          },
          validator: widget.validator,
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              widget.onSelected(value);
            }
          },
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon, color: Colors.yellow[700]),
            suffixIcon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.yellow[700]!),
                      ),
                    ),
                  )
                : null,
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
        if (_showSuggestions)
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
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestion,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  onTap: () {
                    _controller.text = suggestion;
                    widget.onSelected(suggestion);
                    setState(() => _showSuggestions = false);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
