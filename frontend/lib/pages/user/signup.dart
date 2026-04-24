// //signup.dart LAST VERSION
// // ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'login.dart';
import 'home.dart';
import 'package:frontend/pages/service/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final UserService _userService = UserService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',
  );

  void _register() async {
    setState(() {
      _nameError =
          _nameController.text.trim().length < 3
              ? "Name must be at least 3 characters"
              : null;

      _emailError =
          !_emailRegex.hasMatch(_emailController.text.trim())
              ? "Enter a valid email address"
              : null;

      _passwordError =
          !_passwordRegex.hasMatch(_passwordController.text)
              ? "Password must be at least 8 characters, include upper/lowercase letters, number and symbol"
              : null;
    });

    if (_nameError == null && _emailError == null && _passwordError == null) {
      setState(() => _isLoading = true);
      try {
        final user = await _userService.registerUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          final displayName = _nameController.text.trim();

          await user.updateDisplayName(displayName);
          await user.reload();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', displayName);
          await prefs.setString('email', user.email ?? 'Not Provided');

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'id': user.uid,
                'name': displayName,
                'email': user.email,
                'Sessions_history': [],
                'Reservation_history': [],
                'isBlacklisted': false,
                'hasArrived': false,
                'profilePicture': '',
                'vehicles': [],
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Signed up successfully!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            await Future.delayed(const Duration(seconds: 2));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          _showError("Registration failed. Try again.");
        }
      } catch (e) {
        String errorMsg = "Registration failed. Please try again.";
        if (e is fb_auth.FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            errorMsg = "This email is already in use by another account.";
          } else if (e.code == 'weak-password') {
            errorMsg = "Password is too weak.";
          } else if (e.code == 'invalid-email') {
            errorMsg = "Invalid email address.";
          } else {
            errorMsg = "Firebase error: ${e.message}";
          }
        } else {
          errorMsg = "Unexpected error: ${e.toString()}";
        }
        _showError(errorMsg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Registration Failed",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: "Full Name",
                    icon: Icons.person,
                    controller: _nameController,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: "Password",
                    icon: Icons.lock,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[400],
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildButton("Sign Up", _register),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 15),
                      _socialIcon(
                        Colors.red,
                        Icons.g_mobiledata,
                        _loginWithGoogle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.tealAccent),
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.black45,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
