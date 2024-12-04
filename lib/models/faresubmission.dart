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

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'fareAmount': fareAmount,
      'routeTaken': routeTaken,
      'dateTime': dateTime.toIso8601String(),
      'weatherConditions': weatherConditions,
      'trafficConditions': trafficConditions,
      'passengerLoad': passengerLoad,
      'fareContext': fareContext,
      'rushHourStatus': rushHourStatus,
      'userId': userId,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'year': dateTime.year,
      'month': dateTime.month,
      'day': dateTime.day,
      'hour': dateTime.hour,
      'weekday': dateTime.weekday,
    };
  }

  // Create from Firebase Map
  factory FareSubmission.fromMap(Map<String, dynamic> map) {
    return FareSubmission(
      status: map['status'],
      source: map['source'],
      destination: map['destination'],
      fareAmount: map['fareAmount'],
      routeTaken: List<String>.from(map['routeTaken']),
      dateTime: DateTime.parse(map['dateTime']),
      weatherConditions: map['weatherConditions'],
      trafficConditions: map['trafficConditions'],
      passengerLoad: map['passengerLoad'],
      fareContext: map['fareContext'],
      rushHourStatus: map['rushHourStatus'],
      userId: map['userId'],
      submittedAt: DateTime.parse(map['submittedAt']),
    );
  }
}
