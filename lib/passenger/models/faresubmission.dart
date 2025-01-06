class FareSubmission {
  final String source;
  final String destination;
  final double fareAmount;
  final List<String> routeTaken;
  final DateTime dateTime;
  final String weatherConditions;
  final String trafficConditions;
  final String passengerLoad;
  final String? fareContext;
  final String rushHourStatus;
  final String userId;
  final DateTime submittedAt;
  final String status;

  FareSubmission({
    required this.source,
    required this.destination,
    required this.fareAmount,
    required this.routeTaken,
    required this.dateTime,
    required this.weatherConditions,
    required this.trafficConditions,
    required this.passengerLoad,
    this.fareContext,
    required this.rushHourStatus,
    required this.userId,
    required this.submittedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'source': source.toLowerCase().trim(),
      'destination': destination.toLowerCase().trim(),
      'fareAmount': fareAmount,
      'routeTaken': routeTaken.map((l) => l.toLowerCase().trim()).toList(),
      'dateTime': dateTime.toIso8601String(),
      'weatherConditions': weatherConditions,
      'trafficConditions': trafficConditions,
      'passengerLoad': passengerLoad,
      'fareContext': fareContext,
      'rushHourStatus': rushHourStatus,
      'userId': userId,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'metadata': {
        'year': dateTime.year,
        'month': dateTime.month,
        'day': dateTime.day,
        'hour': dateTime.hour,
        'weekday': dateTime.weekday,
      }
    };
  }

  factory FareSubmission.fromMap(Map<String, dynamic> map) {
    return FareSubmission(
      source: map['source'],
      destination: map['destination'],
      fareAmount: map['fareAmount'].toDouble(),
      routeTaken: List<String>.from(map['routeTaken']),
      dateTime: DateTime.parse(map['dateTime']),
      weatherConditions: map['weatherConditions'],
      trafficConditions: map['trafficConditions'],
      passengerLoad: map['passengerLoad'],
      fareContext: map['fareContext'],
      rushHourStatus: map['rushHourStatus'],
      userId: map['userId'],
      submittedAt: DateTime.parse(map['submittedAt']),
      status: map['status'],
    );
  }

  FareSubmission copyWith({
    String? status,
    String? fareContext,
  }) {
    return FareSubmission(
      source: source,
      destination: destination,
      fareAmount: fareAmount,
      routeTaken: routeTaken,
      dateTime: dateTime,
      weatherConditions: weatherConditions,
      trafficConditions: trafficConditions,
      passengerLoad: passengerLoad,
      fareContext: fareContext ?? this.fareContext,
      rushHourStatus: rushHourStatus,
      userId: userId,
      submittedAt: submittedAt,
      status: status ?? this.status,
    );
  }
}
