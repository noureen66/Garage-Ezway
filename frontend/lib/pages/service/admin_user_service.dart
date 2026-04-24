//admin_user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminUserService {
  final String baseUrl = "http://garage.flash-ware.com:3000/admin";

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');

    if (token == null) throw Exception("No admin token found");

    final uri = Uri.parse('$baseUrl/users');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> users = data['users'];
      return users.map((u) => u as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch users: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserPayments(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');

    if (token == null) throw Exception("No admin token found");

    final uri = Uri.parse(
      'http://garage.flash-ware.com:3000/payments/payments-by-user',
    );
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> payments = data['payments'];
      return payments.map((p) => p as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to fetch payments: ${response.body}");
    }
  }

  Future<void> toggleBlacklist(String userId, bool newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');

    if (token == null) throw Exception("No admin token found");

    try {
      final uri = Uri.parse(
        '$baseUrl/blacklist-user',
      ); // <-- Use correct endpoint
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId, 'blacklist': newStatus}),
      );
      print("Sending blacklist-user for userId: $userId");

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception("User not found");
      } else {
        throw Exception("Failed to update blacklist: ${response.body}");
      }
    } catch (e) {
      print("Error in toggleBlacklist: $e");
      throw Exception("Network error occurred");
    }
  }

  Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');

    if (token == null) throw Exception("No admin token found");

    final uri = Uri.parse('$baseUrl/user-by-id');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch user details: ${response.body}");
    }
  }

  Future<int> fetchTotalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');

    if (token == null) throw Exception("No admin token found");

    final uri = Uri.parse('$baseUrl/total-users');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalUsers'] ?? 0;
    } else {
      throw Exception('Failed to load total users: ${response.body}');
    }
  }
}
