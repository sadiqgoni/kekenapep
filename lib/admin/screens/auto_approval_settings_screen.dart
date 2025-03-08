import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keke_fairshare/passenger/services/fare_submission_service.dart'
    as fare_service;

class AutoApprovalSettingsScreen extends StatefulWidget {
  const AutoApprovalSettingsScreen({super.key});

  @override
  State<AutoApprovalSettingsScreen> createState() =>
      _AutoApprovalSettingsScreenState();
}

class _AutoApprovalSettingsScreenState
    extends State<AutoApprovalSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Settings
  bool _enabled = true;
  int _minUserPoints = 15;
  int _minFareAmount = 50;
  int _maxFareAmount = 2000;
  double _maxDeviationFromAverage = 0.3;
  int _minRouteTakenCount = 1;
  bool _requireTimeOfTravel = true;
  bool _requireDateOfTravel = true;
  int _minSubmissionsForTrustedUser = 5;
  int _minApprovedSubmissionsForTrustedUser = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('settings')
          .collection('fare_submission')
          .doc('auto_approval')
          .get();

      if (configDoc.exists) {
        final data = configDoc.data() ?? {};
        setState(() {
          _enabled = data['enabled'] ?? true;
          _minUserPoints = data['minUserPoints'] ?? 15;
          _minFareAmount = data['minFareAmount'] ?? 50;
          _maxFareAmount = data['maxFareAmount'] ?? 2000;
          _maxDeviationFromAverage = data['maxDeviationFromAverage'] ?? 0.3;
          _minRouteTakenCount = data['minRouteTakenCount'] ?? 1;
          _requireTimeOfTravel = data['requireTimeOfTravel'] ?? true;
          _requireDateOfTravel = data['requireDateOfTravel'] ?? true;
          _minSubmissionsForTrustedUser =
              data['minSubmissionsForTrustedUser'] ?? 5;
          _minApprovedSubmissionsForTrustedUser =
              data['minApprovedSubmissionsForTrustedUser'] ?? 3;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final settings = {
        'enabled': _enabled,
        'minUserPoints': _minUserPoints,
        'minFareAmount': _minFareAmount,
        'maxFareAmount': _maxFareAmount,
        'maxDeviationFromAverage': _maxDeviationFromAverage,
        'minRouteTakenCount': _minRouteTakenCount,
        'requireTimeOfTravel': _requireTimeOfTravel,
        'requireDateOfTravel': _requireDateOfTravel,
        'minSubmissionsForTrustedUser': _minSubmissionsForTrustedUser,
        'minApprovedSubmissionsForTrustedUser':
            _minApprovedSubmissionsForTrustedUser,
      };

      await fare_service.FareSubmissionService.updateAutoApprovalConfig(
          settings);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving settings: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Auto-Approval Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('General Settings'),
                    _buildSwitchTile(
                      title: 'Enable Auto-Approval',
                      subtitle:
                          'Automatically approve submissions that meet criteria',
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                    const Divider(),
                    _buildSectionTitle('User Requirements'),
                    _buildNumberField(
                      label: 'Minimum User Points',
                      value: _minUserPoints,
                      onChanged: (value) =>
                          setState(() => _minUserPoints = value),
                      validator: (value) =>
                          value < 0 ? 'Must be positive' : null,
                    ),
                    _buildNumberField(
                      label: 'Minimum Total Submissions',
                      value: _minSubmissionsForTrustedUser,
                      onChanged: (value) =>
                          setState(() => _minSubmissionsForTrustedUser = value),
                      validator: (value) =>
                          value < 0 ? 'Must be positive' : null,
                    ),
                    _buildNumberField(
                      label: 'Minimum Approved Submissions',
                      value: _minApprovedSubmissionsForTrustedUser,
                      onChanged: (value) => setState(
                          () => _minApprovedSubmissionsForTrustedUser = value),
                      validator: (value) =>
                          value < 0 ? 'Must be positive' : null,
                    ),
                    const Divider(),
                    _buildSectionTitle('Fare Amount Validation'),
                    _buildNumberField(
                      label: 'Minimum Fare Amount (₦)',
                      value: _minFareAmount,
                      onChanged: (value) =>
                          setState(() => _minFareAmount = value),
                      validator: (value) =>
                          value < 0 ? 'Must be positive' : null,
                    ),
                    _buildNumberField(
                      label: 'Maximum Fare Amount (₦)',
                      value: _maxFareAmount,
                      onChanged: (value) =>
                          setState(() => _maxFareAmount = value),
                      validator: (value) => value <= _minFareAmount
                          ? 'Must be greater than minimum'
                          : null,
                    ),
                    _buildSliderField(
                      label: 'Maximum Deviation from Average (%)',
                      value: _maxDeviationFromAverage * 100,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) => setState(
                          () => _maxDeviationFromAverage = value / 100),
                    ),
                    const Divider(),
                    _buildSectionTitle('Route Requirements'),
                    _buildNumberField(
                      label: 'Minimum Landmarks Required',
                      value: _minRouteTakenCount,
                      onChanged: (value) =>
                          setState(() => _minRouteTakenCount = value),
                      validator: (value) =>
                          value < 0 ? 'Must be positive' : null,
                    ),
                    _buildSwitchTile(
                      title: 'Require Date of Travel',
                      subtitle: 'Submissions must include date of travel',
                      value: _requireDateOfTravel,
                      onChanged: (value) =>
                          setState(() => _requireDateOfTravel = value),
                    ),
                    _buildSwitchTile(
                      title: 'Require Time of Travel',
                      subtitle: 'Submissions must include time of travel',
                      value: _requireTimeOfTravel,
                      onChanged: (value) =>
                          setState(() => _requireTimeOfTravel = value),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Save Settings',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple[800],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.purple[700],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required String? Function(int) validator,
  }) {
    final controller = TextEditingController(text: value.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.purple[700]!, width: 2),
          ),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field is required';
          }
          final intValue = int.tryParse(value);
          if (intValue == null) {
            return 'Must be a number';
          }
          return validator(intValue);
        },
        onChanged: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            onChanged(intValue);
          }
        },
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  activeColor: Colors.purple[700],
                  inactiveColor: Colors.purple[100],
                  onChanged: onChanged,
                ),
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.purple[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
