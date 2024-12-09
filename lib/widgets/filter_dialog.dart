import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fare_filter.dart';

class FilterDialog extends StatefulWidget {
  final FareFilter? currentFilter;

  const FilterDialog({Key? key, this.currentFilter}) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  DateTime? _fromDate;
  String? _weatherCondition;
  String? _trafficCondition;
  String? _passengerLoad;
  String? _rushHourStatus;

  final List<String> _weatherOptions = ['Clear', 'Rainy', 'Cloudy', 'Dusty'];
  final List<String> _trafficOptions = ['Low', 'Moderate', 'Heavy'];
  final List<String> _passengerLoadOptions = [
    'Solo',
    '2 passengers',
    '3 passengers',
    '4 (One side of driver)',
    '5 (Other side of driver)',
  ];
  final List<String> _rushHourOptions = [
    'Morning (Rush Hour)',
    'Morning (Off-Peak)',
    'Evening (Rush Hour)',
    'Off-Peak Hours',
  ];

  @override
  void initState() {
    super.initState();
    _fromDate = widget.currentFilter?.fromDate;
    _weatherCondition = widget.currentFilter?.weatherCondition;
    _trafficCondition = widget.currentFilter?.trafficCondition;
    _passengerLoad = widget.currentFilter?.passengerLoad;
    _rushHourStatus = widget.currentFilter?.rushHourStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Routes',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[900],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.yellow[700]),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDatePicker(),
                  _buildDropdown(
                    'Weather',
                    _weatherCondition,
                    _weatherOptions,
                    (value) => setState(() => _weatherCondition = value),
                  ),
                  _buildDropdown(
                    'Traffic',
                    _trafficCondition,
                    _trafficOptions,
                    (value) => setState(() => _trafficCondition = value),
                  ),
                  _buildDropdown(
                    'Passenger Load',
                    _passengerLoad,
                    _passengerLoadOptions,
                    (value) => setState(() => _passengerLoad = value),
                  ),
                  _buildDropdown(
                    'Rush Hour Status',
                    _rushHourStatus,
                    _rushHourOptions,
                    (value) => setState(() => _rushHourStatus = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                onPressed: () => Navigator.pop(context, null),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Apply', style: GoogleFonts.poppins()),
                onPressed: () => Navigator.pop(
                  context,
                  FareFilter(
                    fromDate: _fromDate,
                    weatherCondition: _weatherCondition,
                    trafficCondition: _trafficCondition,
                    passengerLoad: _passengerLoad,
                    rushHourStatus: _rushHourStatus,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text('From Date', style: GoogleFonts.poppins()),
      subtitle: Text(
        _fromDate != null
            ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
            : 'Select date',
        style: GoogleFonts.poppins(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fromDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _fromDate = picked);
        }
      },
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.yellow[700]!),
          ),
        ),
        value: value,
        items: [
          const DropdownMenuItem(value: null, child: Text('Any')),
          ...options.map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              )),
        ],
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        dropdownColor: Colors.white,
      ),
    );
  }
} 