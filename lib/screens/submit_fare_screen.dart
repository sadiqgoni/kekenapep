// ignore_for_file: unused_field, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keke_fairshare/models/faresubmission.dart';

class SubmitFareScreen extends StatefulWidget {
  const SubmitFareScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SubmitFareScreenState createState() => _SubmitFareScreenState();
}

class _SubmitFareScreenState extends State<SubmitFareScreen> {
  // Add Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  String? _source;
  String? _destination;
  double? _fareAmount;
  final List<String> _routeTaken = [];
  TimeOfDay? _timeOfTravel;
  DateTime? _dateOfTravel;
  String? _weatherConditions;
  String? _trafficConditions;
  String? _fareContext;
  String? _passengerLoad;
  String _rushHourMessage = '';
  final TextEditingController _landmarkController = TextEditingController();

  final List<String> _weatherOptions = ['Clear', 'Rainy', 'Cloudy', 'Dusty'];
  final List<String> _trafficOptions = ['Low', 'Moderate', 'Heavy'];
  final List<String> _passengerLoadOptions = [
    'Solo',
    '2 passengers',
    '3 passengers',
    '4 (One side of driver)',
    '5 (Other side of driver)',
  ];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfTravel ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _timeOfTravel) {
      setState(() {
        _timeOfTravel = picked;
        _updateRushHourMessage(picked);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfTravel ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dateOfTravel) {
      setState(() {
        _dateOfTravel = picked;
      });
    }
  }

  void _updateRushHourMessage(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 9) {
      _rushHourMessage = 'Morning (Rush Hour)';
    } else if (hour >= 9 && hour < 12) {
      _rushHourMessage = 'Morning (Off-Peak)';
    } else if (hour >= 16 && hour < 19) {
      _rushHourMessage = 'Evening (Rush Hour)';
    } else {
      _rushHourMessage = 'Off-Peak Hours';
    }
  }

  void _addLandmark() {
    if (_landmarkController.text.isNotEmpty) {
      setState(() {
        _routeTaken.add(_landmarkController.text.trim());
        _landmarkController.clear();
      });
    }
  }

  void _removeLandmark(int index) {
    setState(() {
      _routeTaken.removeAt(index);
    });
  }

  Future<void> _submitFare() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_timeOfTravel == null || _dateOfTravel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select both date and time',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Create DateTime combining date and time
        final DateTime combinedDateTime = DateTime(
          _dateOfTravel!.year,
          _dateOfTravel!.month,
          _dateOfTravel!.day,
          _timeOfTravel!.hour,
          _timeOfTravel!.minute,
        );

        // Create FareSubmission object
        final submission = FareSubmission(
          source: _source!,
          destination: _destination!,
          fareAmount: _fareAmount!,
          routeTaken: _routeTaken,
          dateTime: combinedDateTime,
          weatherConditions: _weatherConditions!,
          trafficConditions: _trafficConditions!,
          passengerLoad: _passengerLoad!,
          fareContext: _fareContext!,
          rushHourStatus: _rushHourMessage,
          userId: _auth.currentUser!.uid,
          submittedAt: DateTime.now(),
          status: 'Pending',
        );

        // Add to Firestore with proper collections and subcollections
        await _firestore.runTransaction((transaction) async {
          // Add to main fares collection
          final fareRef = _firestore.collection('fares').doc();
          transaction.set(fareRef, submission.toMap());

          // Add to user's submissions subcollection
          final userRef = _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('submissions')
              .doc(fareRef.id);
          transaction.set(userRef, submission.toMap());

          // Add to routes collection for route analysis
          final routeRef =
              _firestore.collection('routes').doc('${_source}_$_destination');
          transaction.set(
            routeRef,
            {
              'submissions': FieldValue.arrayUnion([fareRef.id]),
              'updatedAt': DateTime.now().toIso8601String(),
              'source': _source,
              'destination': _destination,
            },
            SetOptions(merge: true),
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fare submitted successfully!',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        setState(() {
          _routeTaken.clear();
          _timeOfTravel = null;
          _dateOfTravel = null;
          _weatherConditions = null;
          _trafficConditions = null;
          _passengerLoad = null;
          _fareContext = null;
          _rushHourMessage = '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting fare: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Fare',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSectionTitle('Trip Details'),
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
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Fare Amount (₦)',
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    final sanitizedValue =
                        value?.replaceAll(RegExp(r'[^\d.]'), '');
                    _fareAmount = double.tryParse(sanitizedValue ?? '');
                    if (_fareAmount == null || _fareAmount! <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Invalid fare amount. Please enter a valid value.',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  },
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter fare amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid number greater than zero';
                    }
                    return null;
                  },
                  icon: Icons.money,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Date and Time'),
                _buildDateTimePicker(
                  title: 'Time of Travel',
                  value: _timeOfTravel?.format(context) ?? 'Select Time',
                  icon: Icons.access_time,
                  onTap: () => _selectTime(context),
                ),
                if (_rushHourMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Detected: $_rushHourMessage',
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDateTimePicker(
                  title: 'Date of Travel',
                  value: _dateOfTravel != null
                      ? DateFormat('yyyy-MM-dd').format(_dateOfTravel!)
                      : 'Select Date',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Route Details'),
                _buildLandmarkInput(),
                const SizedBox(height: 16),
                _buildLandmarkChips(),
                const SizedBox(height: 24),
                _buildSectionTitle('Trip Conditions'),
                _buildDropdown(
                  label: 'Weather Conditions',
                  value: _weatherConditions,
                  options: _weatherOptions,
                  onChanged: (value) =>
                      setState(() => _weatherConditions = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Traffic Conditions',
                  value: _trafficConditions,
                  options: _trafficOptions,
                  onChanged: (value) =>
                      setState(() => _trafficConditions = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Passenger Load',
                  value: _passengerLoad,
                  options: _passengerLoadOptions,
                  onChanged: (value) => setState(() => _passengerLoad = value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Additional Information'),
                _buildTextField(
                  label: 'Fare Context (Optional)',
                  maxLines: 3,
                  onSaved: (value) => _fareContext = value,
                  hintText: 'Add any relevant details (optional)',
                  validator: (value) {
                    if (value != null && value.length > 300) {
                      return 'Context is too long. Please limit to 300 characters.';
                    }
                    return null;
                  },
                  icon: Icons.note_alt_outlined,
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Submit Fare',
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
    int maxLines = 1,
    String? hintText,
    required IconData icon,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: DropdownButtonFormField<String>(
          value: value,
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            // contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          validator: (value) => value == null ? 'Please select $label' : null,
          style: GoogleFonts.poppins(color: Colors.black87),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: Colors.yellow[700]),
          isExpanded: false,
          menuMaxHeight: 300,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title:
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: GoogleFonts.poppins()),
      trailing: Icon(icon, color: Colors.yellow[700]),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[300]!),
      ),
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
        _routeTaken.length,
        (index) => Chip(
          label: Text(_routeTaken[index], style: GoogleFonts.poppins()),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeLandmark(index),
          backgroundColor: Colors.yellow[100],
          deleteIconColor: Colors.red[700],
        ),
      ),
    );
  }

  // void _submitFare() {
  //   if (_formKey.currentState!.validate()) {
  //     _formKey.currentState!.save();
  //     // Process fare submission data here
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Fare submitted successfully!',
  //             style: GoogleFonts.poppins()),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   }
  // }
}
