class FareFilter {
  final String? weatherCondition;
  final String? trafficCondition;
  final String? passengerLoad;
  final String? rushHourStatus;
  final DateTime? fromDate;

  FareFilter({
    this.weatherCondition,
    this.trafficCondition,
    this.passengerLoad,
    this.rushHourStatus,
    this.fromDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (weatherCondition != null) 'weatherCondition': weatherCondition,
      if (trafficCondition != null) 'trafficCondition': trafficCondition,
      if (passengerLoad != null) 'passengerLoad': passengerLoad,
      if (rushHourStatus != null) 'rushHourStatus': rushHourStatus,
      if (fromDate != null) 'fromDate': fromDate!.toIso8601String(),
    };
  }

  FareFilter copyWith({
    String? weatherCondition,
    String? trafficCondition,
    String? passengerLoad,
    String? rushHourStatus,
    DateTime? fromDate,
  }) {
    return FareFilter(
      weatherCondition: weatherCondition ?? this.weatherCondition,
      trafficCondition: trafficCondition ?? this.trafficCondition,
      passengerLoad: passengerLoad ?? this.passengerLoad,
      rushHourStatus: rushHourStatus ?? this.rushHourStatus,
      fromDate: fromDate ?? this.fromDate,
    );
  }
}
