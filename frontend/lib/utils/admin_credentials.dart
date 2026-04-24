// import 'package:shared_preferences/shared_preferences.dart';

// class AdminCredentials {
//   static const String _emailKey = 'admin_email';
//   static const String _passwordKey = 'admin_password';

//   static Future<void> initialize() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Set default values only if not already saved
//     if (!prefs.containsKey(_emailKey)) {
//       await prefs.setString(_emailKey, "admin@gmail.com");
//     }
//     if (!prefs.containsKey(_passwordKey)) {
//       await prefs.setString(_passwordKey, "Admin123_");
//     }
//   }

//   static Future<String> getEmail() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_emailKey) ?? "admin@gmail.com";
//   }

//   static Future<String> getPassword() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_passwordKey) ?? "Admin123_";
//   }

//   static Future<void> updatePassword(String newPassword) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_passwordKey, newPassword);
//   }
// }
