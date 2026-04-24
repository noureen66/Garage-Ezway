// // services/booking_storage.dart
// // ignore_for_file: unnecessary_cast
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/booking.dart';

class BookingStorage {
  static String getKeyForUser(String userId) => 'booking_history_$userId';

  static Future<void> addBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getKeyForUser(booking.userId);
    final history = await getBookingHistoryForUser(booking.userId);
    history.add(booking);

    final jsonList = history.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(key, jsonList);
  }

  static Future<List<Booking>> getBookingHistoryForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = getKeyForUser(userId);
    final storedData = prefs.get(key);
    if (storedData is! List<String>) {
      await prefs.remove(key);
      return [];
    }

    return storedData.map((jsonStr) {
      final map = jsonDecode(jsonStr);
      return Booking.fromJson(map);
    }).toList();
  }
}
