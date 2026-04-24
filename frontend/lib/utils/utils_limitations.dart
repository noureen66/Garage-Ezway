// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<Map<String, dynamic>> checkBanStatus(String userId) async {
//   final prefs = await SharedPreferences.getInstance();

//   final int badReservations = prefs.getInt('bad_reservations') ?? 0;
//   final String? sessionStartStr = prefs.getString('parking_start_time');
//   final String? sessionEndStr = prefs.getString('parking_end_time');
//   final bool paymentCompleted = prefs.getBool('payment_completed') ?? true;
//   final int? banStartMillis = prefs.getInt('ban_start_time');

//   bool isBanned = false;
//   String reason = '';
//   int unpaidAmount = 0;

//   final now = DateTime.now();

//   // 🚫 Rule 1: Too many reservations
//   if (badReservations >= 5) {
//     if (banStartMillis != null) {
//       final String? banStart = prefs.getString('ban_start_time');

//       if (now.difference(banStart).inHours < 24) {
//         isBanned = true;
//         reason = 'Banned for 24h due to 5+ unused reservations.';
//       } else {
//         prefs.setInt('bad_reservations', 0);
//         prefs.remove('ban_start_time');
//         await FirebaseFirestore.instance.collection('users').doc(userId).update(
//           {'isBlacklisted': false},
//         );
//       }
//     } else {
//       // Start ban
//       prefs.setInt('ban_start_time', now.millisecondsSinceEpoch);
//       await FirebaseFirestore.instance.collection('users').doc(userId).update({
//         'isBlacklisted': true,
//       });
//       isBanned = true;
//       reason = 'Banned for 24h due to 5+ unused reservations.';
//     }
//   }

//   // ⏱ Rule 2: Session longer than 24 hours
//   if (sessionStartStr != null && sessionEndStr == null) {
//     final start = DateTime.tryParse(sessionStartStr);
//     if (start != null && now.difference(start).inHours >= 24) {
//       isBanned = true;
//       reason = 'Exceeded 24h parking time. Please pay to unban.';
//       unpaidAmount = 200;
//     }
//   }

//   // 💸 Rule 3: Session ended but unpaid
//   if (sessionStartStr != null &&
//       sessionEndStr != null &&
//       paymentCompleted == false) {
//     isBanned = true;
//     reason = 'Unpaid session. Please pay to unban.';
//     unpaidAmount = prefs.getInt('unpaid_amount') ?? 0;
//   }

//   return {'isBanned': isBanned, 'reason': reason, 'unpaidAmount': unpaidAmount};
// }
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>> checkBanStatus(String userId) async {
  final prefs = await SharedPreferences.getInstance();

  final int badReservations = prefs.getInt('bad_reservations') ?? 0;
  final String? sessionStartStr = prefs.getString('parking_start_time');
  final String? sessionEndStr = prefs.getString('parking_end_time');
  final bool paymentCompleted = prefs.getBool('payment_completed') ?? true;
  final String? banStartStr = prefs.getString('ban_start_time');

  bool isBanned = false;
  String reason = '';
  int unpaidAmount = 0;

  final now = DateTime.now();

  // 🚫 Rule 1: Too many reservations
  if (badReservations >= 5) {
    if (banStartStr != null) {
      final banStart = DateTime.tryParse(banStartStr);
      if (banStart != null && now.difference(banStart).inHours < 24) {
        isBanned = true;
        reason = 'Banned for 24h due to 5+ unused reservations.';
      } else {
        // Ban expired
        prefs.setInt('bad_reservations', 0);
        prefs.remove('ban_start_time');
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'isBlacklisted': false},
        );
      }
    } else {
      // Start new ban
      prefs.setString('ban_start_time', now.toIso8601String());
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlacklisted': true,
      });
      isBanned = true;
      reason = 'Banned for 24h due to 5+ unused reservations.';
    }
  }

  // ⏱ Rule 2: Session longer than 24 hours
  if (sessionStartStr != null && sessionEndStr == null) {
    final start = DateTime.tryParse(sessionStartStr);
    if (start != null && now.difference(start).inHours >= 24) {
      isBanned = true;
      reason = 'Exceeded 24h parking time. Please pay to unban.';
      unpaidAmount = 200;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlacklisted': true,
      });
    }
  }

  // 💸 Rule 3: Session ended but unpaid
  if (sessionStartStr != null &&
      sessionEndStr != null &&
      paymentCompleted == false) {
    isBanned = true;
    reason = 'Unpaid session. Please pay to unban.';
    unpaidAmount = prefs.getInt('unpaid_amount') ?? 0;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBlacklisted': true,
    });
  }

  return {'isBanned': isBanned, 'reason': reason, 'unpaidAmount': unpaidAmount};
}
