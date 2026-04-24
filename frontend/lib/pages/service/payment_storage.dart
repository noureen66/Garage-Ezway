// // lib/pages/service/payment_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentStorage {
  static const _key = 'payment_history';

  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final historyStr = prefs.getString(_key);
    final history = historyStr != null ? List.from(jsonDecode(historyStr)) : [];

    final exists = history.any(
      (item) =>
          item['id'] == transaction['id'] ||
          (item['createdAt'] == transaction['createdAt'] &&
              item['amount'] == transaction['amount']),
    );

    if (!exists) {
      history.add(transaction);
      await prefs.setString(_key, jsonEncode(history));
    }
  }

  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_key);

    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);

      final uniqueHistory =
          decoded
              .fold<Map<String, dynamic>>({}, (map, item) {
                final id = item['id'] ?? item['createdAt'];
                if (!map.containsKey(id)) {
                  map[id] = item;
                }
                return map;
              })
              .values
              .toList();

      return uniqueHistory.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }
}
