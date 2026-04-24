class Booking {
  final DateTime time;
  final String location;
  final double amount;
  final String userId;

  Booking({
    required this.time,
    required this.location,
    required this.amount,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'location': location,
    'amount': amount,
    'userId': userId,
  };

  static Booking fromJson(Map<String, dynamic> json) => Booking(
    time: DateTime.parse(json['time']),
    location: json['location'],
    amount: json['amount'],
    userId: json['userId'] ?? '',
  );
}
