// // // //login.dart LAST VERSION
import 'package:flutter/material.dart';
import 'signup.dart';
import 'home.dart';
import 'package:frontend/pages/admin/admin_home.dart';
import 'package:frontend/pages/user/forgot_password_email.dart';
import 'package:frontend/pages/service/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final _userService = UserService();

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  _buildEmail(),
                  const SizedBox(height: 15),
                  _buildPassword(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const ForgotPasswordEmailPage(),
                                ),
                              ),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildButton("Login", _handleEmailPassword),
                  const SizedBox(height: 20),
                  _buildSocialButtons(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmail() => TextField(
    controller: _email,
    keyboardType: TextInputType.emailAddress,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: "Email",
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.black45,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildPassword() => TextField(
    controller: _password,
    obscureText: !_showPassword,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: "Password",
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
      suffixIcon: IconButton(
        icon: Icon(
          _showPassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[400],
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
      filled: true,
      fillColor: Colors.black45,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildButton(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
  );

  Widget _buildSocialButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(width: 15),
      _socialIcon(Colors.red, Icons.g_mobiledata, _loginWithGoogle),
    ],
  );

  Widget _socialIcon(Color bg, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg.withOpacity(0.2),
          ),
          child: Icon(icon, color: bg, size: 30),
        ),
      );

  Future<void> _handleEmailPassword() async {
    final email = _email.text.trim();
    final pass = _password.text;

    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse("http://garage.flash-ware.com:3000/admin/login");
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': pass}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', token);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Admin login successful!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomePage()),
          );
        }
        return;
      }

      // If backend returned error for admin, continue with user login
    } catch (e) {
      // If backend request fails, continue with user login
    }

    // Try user login
    try {
      final user = await _userService.loginUser(email, pass);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', user.displayName ?? 'Unknown');
        await prefs.setString('email', user.email ?? 'No Email');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Logged in successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showError("Authentication failed.");
      }
    } catch (_) {
      _showError(
        "Login failed, the password or the email you entered is incorrect.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showError("Google sign-in cancelled.");
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', user.displayName ?? "Unknown");
        await prefs.setString('email', user.email ?? "No Email");

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': user.displayName ?? "Unknown",
          'email': user.email ?? "",
          'Sessions_history': [],
          'Reservation_history': [],
          'isBlacklisted': false,
          'paymentHistory': [],
          'paymentCreditCards': [],
          'profilePicture': '',
          'vehicles': [],
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Signed in successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showError("Failed to log in with Google.");
      }
    } catch (e) {
      _showError("Google sign-in failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Login Failed",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(msg, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.tealAccent),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
