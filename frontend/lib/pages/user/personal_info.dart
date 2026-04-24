//personal_information.dart LAST VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile.dart';
import 'package:frontend/pages/user/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _name = "User Name";
  String _email = "Not Provided";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      setState(() {
        _name = prefs.getString('name') ?? _name;
        _email = prefs.getString('email') ?? _email;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName(String name) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEmail(String email) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editName() async {
    if (_isLoading) return;
    String tempName = _name;

    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter your name"),
            onChanged: (value) {
              tempName = value;
            },
            controller: TextEditingController(text: _name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (tempName.trim().isNotEmpty) {
                  Navigator.pop(context, tempName.trim());
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _name = newName;
      });
      await _saveName(newName);
    }
  }

  void _editEmail() async {
    if (_isLoading) return;
    String tempEmail = _email;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    String? newEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        String? errorText;
        final controller = TextEditingController(text: _email);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Email"),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  errorText: errorText,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (!emailRegex.hasMatch(value)) {
                    setState(() {
                      errorText = "Invalid email format";
                    });
                  } else {
                    setState(() {
                      errorText = null;
                    });
                  }
                  tempEmail = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (emailRegex.hasMatch(tempEmail.trim())) {
                      Navigator.pop(context, tempEmail.trim());
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (newEmail != null && newEmail.isNotEmpty) {
      setState(() {
        _email = newEmail;
      });
      await _saveEmail(newEmail);
    }
  }

  Future<String> _askPassword(BuildContext context) async {
    String password = '';
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Re-authentication required'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter your password'),
            onChanged: (value) => password = value,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, ''),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.pop(context, password),
            ),
          ],
        );
      },
    ).then((value) => value ?? '');
  }

  void _deleteAccount() async {
    if (_isLoading) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account? This will remove your name, email, booking history, all added vehicles, your profile picture, saved cards, and payment history.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final providers = await user.providerData;
        final signInMethod = providers.first.providerId;
        if (signInMethod == 'password') {
          final password = await _askPassword(context);
          if (password.isEmpty) {
            setState(() => _isLoading = false);
            return;
          }

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          await user.reauthenticateWithCredential(credential);
        } else if (signInMethod == 'google.com') {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          final googleUser = await googleSignIn.signIn();

          if (googleUser == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Google reauthentication canceled.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await user.reauthenticateWithCredential(credential);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Unsupported sign-in method: $signInMethod'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final uid = user.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await user.delete();

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!mounted) return;

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.redAccent,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Incorrect password. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (e.code == 'requires-recent-login') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('This operation requires recent login.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Auth error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "GARAGE ",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: "EZway",
                style: GoogleFonts.dancingScript(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              ListTile(
                title: Text("Name", style: TextStyle(color: Colors.white)),
                trailing: Text(_name, style: TextStyle(color: Colors.white)),
                onTap: _editName,
              ),
              Divider(color: Colors.grey),
              ListTile(
                title: Text("Email", style: TextStyle(color: Colors.white)),
                trailing: Text(_email, style: TextStyle(color: Colors.grey)),
                onTap: _editEmail,
              ),
              Divider(color: Colors.grey),
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("You have been logged out."),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        await Future.delayed(const Duration(seconds: 1));
                        if (!mounted) return;
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Log out",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Delete my account",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
