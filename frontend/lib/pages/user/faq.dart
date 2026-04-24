// // // //FAQ.dart LAST VERSION
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nave_bar.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<String> _questions = [
    'What is garage ezway?',
    'How do I start parking?',
    'Can I save my vehicle info?',
    'Is my payment information safe?',
    'I need help with a problem',
  ];

  String? _selectedQuestion;
  String _botResponse = '';
  bool _showConfirmButton = false;

  String _getBotResponse(String question) {
    question = question.toLowerCase();

    if (question.contains("what") && question.contains("garage")) {
      return "Garage EZway is a smart parking management app that allows you to easily book, start, and end parking sessions, monitor real-time parking availability, securely handle payments, and manage detailed vehicle profiles — all designed to save time and enhance your parking experience.";
    } else if (question.contains("start") && question.contains("parking")) {
      return "You can easily select your preferred parking location, choose a slot, start a new parking session with a single tap, monitor the ongoing duration and cost in real-time, and end the session whenever you're ready.";
    } else if (question.contains("vehicle")) {
      return "Yes, you can save or delete your vehicle in the Profile section.";
    } else if (question.contains("safe") || question.contains("payment")) {
      return "Yes, your payment information is securely processed.";
    } else if (question.contains("problem") ||
        question.contains("help") ||
        question.contains("support")) {
      return "Admin will email you for the reported problem.";
    } else {
      return "Sorry, I don't understand your question.";
    }
  }

  void _handleQuestionSelection(String question) {
    final response = _getBotResponse(question);

    setState(() {
      _botResponse = response;
      _showConfirmButton =
          question.contains("problem") ||
          question.contains("help") ||
          question.contains("support");
    });
  }

  Future<void> _saveReportLocally() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Unknown user';
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final reportMessage =
        "[$formattedDate $formattedTime]\nThe user: $userId has reported a problem";
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('reports') ?? [];
    reports.add(reportMessage);

    await prefs.setStringList('reports', reports);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Your report has been sent to the admin. He will email you shortly.',
        ),
      ),
    );

    setState(() {
      _showConfirmButton = false;
      _botResponse =
          "Your report has been sent to the admin. He will email you shortly.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "GARAGE ",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: "EZway",
                style: GoogleFonts.dancingScript(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                "Ask the chatbot",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedQuestion,
              dropdownColor: const Color(0xFF1A2B3C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              hint: const Text(
                'Select your question',
                style: TextStyle(color: Colors.white54),
              ),
              items:
                  _questions.map((q) {
                    return DropdownMenuItem(
                      value: q,
                      child: Text(
                        q,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuestion = value;
                });
                if (value != null) {
                  _handleQuestionSelection(value);
                }
              },
            ),
            if (_botResponse.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _botResponse,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            if (_showConfirmButton)
              ElevatedButton(
                onPressed: _saveReportLocally,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("Confirm Report"),
              ),
          ],
        ),
      ),
      floatingActionButton: const FloatingCircularNavBar(currentPage: ''),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
