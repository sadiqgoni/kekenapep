class FareFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? weatherCondition;
  final String? trafficCondition;
  final String? passengerLoad;
  final String? rushHourStatus;

  FareFilter({
    this.fromDate,
    this.toDate,
    this.weatherCondition,
    this.trafficCondition,
    this.passengerLoad,
    this.rushHourStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'weatherCondition': weatherCondition,
      'trafficCondition': trafficCondition,
      'passengerLoad': passengerLoad,
      'rushHourStatus': rushHourStatus,
    };
  }
} 