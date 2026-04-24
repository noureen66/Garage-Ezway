import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_slot_moa.dart';
import 'book_slot_cfc.dart';
import 'book_slot_cs.dart';
import 'book_slot.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nave_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Map<String, dynamic>> malls = [
    {
      "name": "Mall of Arabia",
      "icon": Icons.shopping_bag,
      "color": Colors.orange,
    },
    {"name": "City Stars", "icon": Icons.star, "color": Colors.yellow},
    {
      "name": "Cairo Festival City Mall",
      "icon": Icons.festival,
      "color": Colors.pinkAccent,
    },
    {
      "name": "Maquette",
      "icon": Icons.location_city,
      "color": Colors.lightBlueAccent,
    },
  ];

  bool isBanned = false;
  String banReason = '';
  Duration remainingBanTime = Duration.zero;
  int unpaidAmount = 0;

  @override
  void initState() {
    super.initState();
    _checkBlacklist();
  }

  Future<void> _checkBlacklist() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final firestoreBlacklisted = userDoc.data()?['isBlacklisted'] ?? false;

    bool localBanActive = false;
    String localBanReason = prefs.getString('banReason') ?? '';
    int? localBannedUntil = prefs.getInt('bannedUntil');

    if (localBanReason.isNotEmpty && localBannedUntil != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs < localBannedUntil) {
        setState(() {
          isBanned = true;
          banReason = localBanReason;
          remainingBanTime = Duration(milliseconds: localBannedUntil - nowMs);
        });
        localBanActive = true;
      } else {
        await prefs.remove('banReason');
        await prefs.remove('bannedUntil');
      }
    }

    if (firestoreBlacklisted && !localBanActive) {
      setState(() {
        isBanned = true;
        banReason = "🚫 You are blacklisted and cannot book.";
        remainingBanTime = Duration.zero;
      });
    } else if (!firestoreBlacklisted && !localBanActive) {
      setState(() {
        isBanned = false;
        banReason = '';
        remainingBanTime = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: FloatingCircularNavBar(currentPage: 'search'),

      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        elevation: 2,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "GARAGE ",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: "EZway",
                style: GoogleFonts.dancingScript(
                  color: Colors.white,
                  fontSize: 22,
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
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = snapshot.data as SharedPreferences;
          final reservedSlot = prefs.getString('selected_slot_id');
          final bookingTimeStr = prefs.getString('booking_time');
          final parkingStartStr = prefs.getString('parking_start_time');

          DateTime? bookingTime =
              bookingTimeStr != null ? DateTime.tryParse(bookingTimeStr) : null;
          DateTime? parkingStartTime =
              parkingStartStr != null
                  ? DateTime.tryParse(parkingStartStr)
                  : null;

          bool hasActiveReservation = false;
          bool hasActiveSession = parkingStartTime != null;
          bool reservationExpired = false;

          if (reservedSlot != null && bookingTime != null) {
            final difference = DateTime.now().difference(bookingTime);
            if (difference < const Duration(minutes: 30)) {
              hasActiveReservation = true;
            } else {
              reservationExpired = true;
            }
          }

          if (reservationExpired) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              prefs.remove('selected_slot_id');
              prefs.remove('booking_time');
              prefs.remove('selected_mall');
            });
          }

          final reservationActive = hasActiveReservation || hasActiveSession;
          final disableBooking = reservationActive || isBanned;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Available Malls",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (reservationActive)
                _warningBox("⚠️ You already have a reservation or session."),
              if (isBanned) _banBox(),
              Expanded(
                child: ListView.builder(
                  itemCount: malls.length,
                  itemBuilder: (context, index) {
                    final mall = malls[index];

                    return Card(
                      color:
                          disableBooking
                              ? const Color(0xFF2F3E50)
                              : const Color(0xFF1A2A3F),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              disableBooking ? Colors.grey : mall["color"],
                          child: Icon(mall["icon"], color: Colors.white),
                        ),
                        title: Text(
                          mall["name"],
                          style: TextStyle(
                            color:
                                disableBooking
                                    ? Colors.grey[400]
                                    : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          disableBooking ? Icons.lock : Icons.arrow_forward_ios,
                          color:
                              disableBooking
                                  ? Colors.redAccent
                                  : Colors.white70,
                          size: 16,
                        ),
                        enabled: !disableBooking,
                        onTap:
                            disableBooking
                                ? () {
                                  String msg =
                                      isBanned
                                          ? "🚫 You are banned from booking.\n$banReason"
                                          : "⚠️ You already have a reservation or session.";
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                                : () async {
                                  await prefs.setString(
                                    'selected_mall',
                                    mall["name"],
                                  );
                                  Widget destinationPage;
                                  switch (mall["name"]) {
                                    case "Mall of Arabia":
                                      destinationPage = BookSlotMOAPage();
                                      break;
                                    case "City Stars":
                                      destinationPage = BookSlotCSPage();
                                      break;
                                    case "Cairo Festival City Mall":
                                      destinationPage = BookSlotCfc();
                                      break;
                                    default:
                                      destinationPage = BookSlotPage();
                                  }
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => destinationPage,
                                      ),
                                    );
                                  }
                                },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _warningBox(String text) => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[700],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _banBox() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[800],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "You are banned",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(banReason, style: const TextStyle(color: Colors.white70)),
        if (remainingBanTime > Duration.zero)
          Text(
            "Ban expires in: ${_formatDuration(remainingBanTime)}",
            style: const TextStyle(color: Colors.white54),
          ),
        if (unpaidAmount > 0)
          ElevatedButton.icon(
            onPressed: _handleUnbanPayment,
            icon: const Icon(Icons.payment),
            label: const Text("Pay & Unban"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
      ],
    ),
  );

  Future<void> _handleUnbanPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isBlacklisted': false},
      );
      await prefs.remove('banReason');
      await prefs.remove('bannedUntil');
      await prefs.setInt('unpaid_amount', 0);
      await prefs.setBool('payment_completed', true);

      setState(() {
        isBanned = false;
        unpaidAmount = 0;
        banReason = '';
        remainingBanTime = Duration.zero;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Payment successful. You are now unbanned."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
