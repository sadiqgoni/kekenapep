class FareSubmission {
  final String id;
  final String userId;
  final double amount;
  final DateTime timestamp;
  final String route;
  final String driverName;
  final String vehicleNumber;

  FareSubmission({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
    required this.route,
    required this.driverName,
    required this.vehicleNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'route': route,
      'driverName': driverName,
      'vehicleNumber': vehicleNumber,
    };
  }

  factory FareSubmission.fromMap(Map<String, dynamic> map) {
    return FareSubmission(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      route: map['route'],
      driverName: map['driverName'],
      vehicleNumber: map['vehicleNumber'],
    );
  }
}
