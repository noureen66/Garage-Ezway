// lib/pages/model/user_model.dart
import 'booking.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final List<Booking> bookings;
  final bool? isBlacklisted;
  final List<Map<String, dynamic>> paymentHistory;
  final List<String> paymentCreditCards;
  final String? profilePicture;
  final List<String> vehicles;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.bookings = const [],
    this.isBlacklisted = false,
    this.paymentHistory = const [],
    this.paymentCreditCards = const [],
    this.profilePicture,
    this.vehicles = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    List<Booking>? bookings,
    bool? isBlacklisted,
    List<Map<String, dynamic>>? paymentHistory,
    List<String>? paymentCreditCards,
    String? profilePicture,
    List<String>? vehicles,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      bookings: bookings ?? this.bookings,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      paymentCreditCards: paymentCreditCards ?? this.paymentCreditCards,
      profilePicture: profilePicture ?? this.profilePicture,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'bookings': bookings.map((b) => b.toJson()).toList(),
    'isBlacklisted': isBlacklisted,
    'paymentHistory': paymentHistory,
    'paymentCreditCards': paymentCreditCards,
    'profilePicture': profilePicture,
    'vehicles': vehicles,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
    bookings:
        (json['bookings'] as List<dynamic>?)
            ?.map((b) => Booking.fromJson(b))
            .toList() ??
        [],
    isBlacklisted: json['isBlacklisted'] ?? false,
    paymentHistory:
        (json['paymentHistory'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [],
    paymentCreditCards:
        (json['paymentCreditCards'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    profilePicture: json['profilePicture'],
    vehicles:
        (json['vehicles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );
}
