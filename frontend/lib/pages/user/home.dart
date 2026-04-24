//home.dart LAST VERSION
// ignore_for_file: unused_field
//ERROR HANDLING DONE
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/user/book_slot_cs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Search.dart';
import 'edit_vehicle.dart';
import 'active_session.dart';
import 'package:frontend/pages/user/book_slot_cfc.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/pages/user/faq.dart';
import 'nave_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _DraggableChatbotButton extends StatefulWidget {
  @override
  State<_DraggableChatbotButton> createState() =>
      _DraggableChatbotButtonState();
}

class _DraggableChatbotButtonState extends State<_DraggableChatbotButton> {
  double posX = 300;
  double posY = 600;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            posX = (posX + details.delta.dx).clamp(0.0, screenSize.width - 60);
            posY = (posY + details.delta.dy).clamp(0.0, screenSize.height - 60);
          });
        },
        onTap: () async {
          try {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FAQPage()),
            );
          } catch (e, stackTrace) {
            debugPrint("Error navigating to FAQPage: $e");
            debugPrint(stackTrace.toString());

            if (ScaffoldMessenger.maybeOf(context) != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Failed to open chatbot. Please try again."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.tealAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.chat, color: Colors.black87, size: 30),
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _defaultVehicleName = "No vehicle selected";
  String _defaultVehicleImage = "assets/icons/car1.png";
  bool _hasActiveSession = false;
  MemoryImage? _profileMemoryImage;
  bool _hasReservation = false;
  String? _reservedSlotId;
  String? _reservedMallName;
  late final Ticker _reservationTicker;

  bool isBanned = false;
  String banReason = '';
  int bannedUntil = 0;
  int unpaidAmount = 0;
  Duration remainingBanTime = Duration.zero;
  Timer? _banTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultVehicle();
      _checkActiveSession();
      _loadProfileImage();
      checkBanStatus();
    });

    _reservationTicker = Ticker((_) async {
      await _checkActiveSession();
    })..start();
    // Firebase Messaging listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🌟 Received a message while in foreground!');
      print('Data: ${message.data}');
      if (message.notification != null) {
        print('Notification title: ${message.notification!.title}');
        print('Notification body: ${message.notification!.body}');
      }

      if (mounted && ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? 'New Notification'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App opened from background by tapping notification');
    });
  }

  @override
  void dispose() {
    _reservationTicker.dispose();
    _banTimer?.cancel();
    super.dispose();
  }

  Future<void> checkBanStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      // Get isBlacklisted from backend
      final isBlacklisted = doc.data()?['isBlacklisted'] ?? false;

      // If blacklisted from backend, we show the ban UI and disable actions
      if (isBlacklisted) {
        if (!mounted) return;
        setState(() {
          isBanned = true;
          banReason = "Your account has been blacklisted by the admin.";
          remainingBanTime = Duration.zero;
          unpaidAmount = 0;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final badReservations = prefs.getInt('bad_reservations') ?? 0;
      final String? banStartStr = prefs.getString('ban_start_time');
      final String? sessionStartStr = prefs.getString('parking_start_time');
      final String? sessionEndStr = prefs.getString('parking_end_time');
      final bool paymentCompleted = prefs.getBool('payment_completed') ?? true;
      final int unpaidAmt = prefs.getInt('unpaid_amount') ?? 0;

      final now = DateTime.now();
      bool localIsBanned = false;
      String localBanReason = '';
      Duration localRemainingTime = Duration.zero;

      if (badReservations >= 5) {
        if (banStartStr != null) {
          final banStart = DateTime.tryParse(banStartStr);
          if (banStart != null) {
            final diff = now.difference(banStart);
            if (diff < const Duration(seconds: 10)) {
              localIsBanned = true;
              localBanReason =
                  "You reserved too many times without starting a session.";
              localRemainingTime = const Duration(seconds: 10) - diff;
            } else {
              await prefs.setInt('bad_reservations', 0);
              await prefs.remove('ban_start_time');
            }
          }
        } else {
          await prefs.setString('ban_start_time', now.toIso8601String());
          localIsBanned = true;
          localBanReason =
              "You reserved too many times without starting a session.";
          localRemainingTime = const Duration(seconds: 10);
        }
      }

      if (sessionStartStr != null && sessionEndStr == null) {
        final sessionStart = DateTime.tryParse(sessionStartStr);
        if (sessionStart != null &&
            now.difference(sessionStart).inHours >= 24) {
          localIsBanned = true;
          localBanReason =
              "Your session exceeded 24 hours. Please pay to unblock.";
        }
      }

      if (sessionStartStr != null &&
          sessionEndStr != null &&
          !paymentCompleted) {
        localIsBanned = true;
        localBanReason =
            "You didn’t pay for the last session. Please pay to unblock.";
      }

      if (!mounted) return;
      setState(() {
        isBanned = localIsBanned;
        banReason = localBanReason;
        remainingBanTime = localRemainingTime;
        unpaidAmount = unpaidAmt;
      });

      if (localIsBanned && localRemainingTime > Duration.zero) {
        _banTimer?.cancel();
        _banTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (remainingBanTime.inSeconds <= 1) {
            timer.cancel();
            if (mounted) {
              setState(() {
                isBanned = false;
                banReason = '';
                remainingBanTime = Duration.zero;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                remainingBanTime =
                    remainingBanTime - const Duration(seconds: 1);
              });
            }
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error in checkBanStatus: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to check ban status. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImage = prefs.getString('profile_image');

      if (savedImage != null && savedImage.isNotEmpty) {
        try {
          final imageBytes = base64Decode(savedImage);
          if (mounted) {
            setState(() {
              _profileMemoryImage = MemoryImage(imageBytes);
            });
          }
        } catch (e) {
          debugPrint("Error decoding profile image: $e");
          if (mounted) {
            setState(() {
              _profileMemoryImage = null;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _profileMemoryImage = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile image from SharedPreferences: $e");
      if (mounted) {
        setState(() {
          _profileMemoryImage = null;
        });
      }
    }
  }

  Future<void> _checkActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStart = prefs.getString('parking_start_time');
      final bookingTimeStr = prefs.getString('booking_time');

      DateTime? bookingTime;
      if (bookingTimeStr != null && bookingTimeStr.isNotEmpty) {
        bookingTime = DateTime.tryParse(bookingTimeStr);
        if (bookingTime == null) {
          debugPrint("Invalid booking_time format in SharedPreferences.");
        }
      }

      final bool sessionStarted = savedStart != null;
      bool expired = false;

      if (!sessionStarted && bookingTime != null) {
        final diff = DateTime.now().difference(bookingTime);
        expired = diff >= const Duration(minutes: 30);

        if (expired) {
          await prefs.remove('selected_slot_id');
          await prefs.remove('selected_floor');
          await prefs.remove('booking_time');
          await prefs.remove('selected_mall');
          debugPrint(
            "Reservation expired: data cleared from SharedPreferences.",
          );
        }
      }

      final updatedSlot = prefs.getString('selected_slot_id');
      final updatedMall = prefs.getString('selected_mall');
      final updatedBookingTimeStr = prefs.getString('booking_time');

      DateTime? updatedBookingTime;
      if (updatedBookingTimeStr != null && updatedBookingTimeStr.isNotEmpty) {
        updatedBookingTime = DateTime.tryParse(updatedBookingTimeStr);
        if (updatedBookingTime == null) {
          debugPrint(
            "Invalid updated booking_time format in SharedPreferences.",
          );
        }
      }

      final bool hasValidReservation =
          updatedSlot != null &&
          updatedBookingTime != null &&
          DateTime.now().difference(updatedBookingTime) <
              const Duration(minutes: 30);

      if (mounted) {
        setState(() {
          _hasActiveSession = sessionStarted;
          _hasReservation = !sessionStarted && hasValidReservation;
          _reservedSlotId = hasValidReservation ? updatedSlot : null;
          _reservedMallName = hasValidReservation ? updatedMall : null;
        });
      }

      if (expired && mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reservation expired after 30 minutes."),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e, stackTrace) {
      debugPrint("Error in _checkActiveSession: $e");
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() {
          _hasActiveSession = false;
          _hasReservation = false;
          _reservedSlotId = null;
          _reservedMallName = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred while checking the session."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadDefaultVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehiclesString = prefs.getString('vehicles');
      String? defaultName = prefs.getString('default_vehicle_name');
      String? defaultImage;

      List<Map<String, dynamic>> vehicles = [];

      if (vehiclesString != null && vehiclesString.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(vehiclesString);
          vehicles =
              decoded
                  .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e),
                  )
                  .toList();
        } catch (e) {
          debugPrint("Failed to decode vehicles JSON: $e");
        }
      }

      if ((defaultName == null || defaultName.isEmpty) && vehicles.isNotEmpty) {
        final defaultVehicle = vehicles.firstWhere(
          (v) => v["isDefault"] == true,
          orElse: () => {},
        );

        if (defaultVehicle.isNotEmpty) {
          defaultName = defaultVehicle["name"] as String?;
          defaultImage =
              defaultVehicle["image"] as String? ?? "assets/icons/car1.png";
        }
      }

      if ((defaultImage == null || defaultImage.isEmpty) &&
          vehicles.isNotEmpty) {
        final defaultVehicle = vehicles.firstWhere(
          (v) => v["isDefault"] == true,
          orElse: () => {},
        );

        if (defaultVehicle.isNotEmpty) {
          defaultImage =
              defaultVehicle["image"] as String? ?? "assets/icons/car1.png";
        }
      }

      if (mounted) {
        setState(() {
          _defaultVehicleName = defaultName ?? "No vehicle selected";
          _defaultVehicleImage = defaultImage ?? "assets/icons/car1.png";
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error in _loadDefaultVehicle: $e");
      debugPrint(stackTrace.toString());

      if (mounted) {
        setState(() {
          _defaultVehicleName = "No vehicle selected";
          _defaultVehicleImage = "assets/icons/car1.png";
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load vehicle data."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshVehicle() async {
    await _loadDefaultVehicle();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                if (isBanned)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.block, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              "You are banned",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            if (remainingBanTime > Duration.zero) ...[
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${remainingBanTime.inHours.toString().padLeft(2, '0')}:${(remainingBanTime.inMinutes % 60).toString().padLeft(2, '0')}:${(remainingBanTime.inSeconds % 60).toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banReason,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (remainingBanTime > Duration.zero)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer, color: Colors.white70),
                                const SizedBox(width: 10),
                                Text(
                                  "Ban expires in: ${remainingBanTime.inHours.toString().padLeft(2, '0')}:${(remainingBanTime.inMinutes % 60).toString().padLeft(2, '0')}:${(remainingBanTime.inSeconds % 60).toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (unpaidAmount > 0)
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('payment_completed', true);
                                await prefs.setInt('unpaid_amount', 0);
                                await prefs.remove('ban_start_time');
                                await prefs.setInt('bad_reservations', 0);

                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser.uid)
                                      .update({'isBlacklisted': false});
                                }

                                if (mounted) {
                                  setState(() {
                                    isBanned = false;
                                    unpaidAmount = 0;
                                    banReason = '';
                                    remainingBanTime = Duration.zero;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Payment successful. Unbanned.",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e, stackTrace) {
                                debugPrint("Error during payment unban: $e");
                                debugPrint(stackTrace.toString());

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Payment failed. Please try again.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.payment),
                            label: Text("Pay EGP $unpaidAmount"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _buildSearchBar(context, isBanned),
                const SizedBox(height: 30),
                _buildVehicleCard(screenHeight),
                if (_hasReservation) ...[
                  const SizedBox(height: 30),
                  _buildReservationBox(context),
                ],
                if (_hasActiveSession) ...[
                  const SizedBox(height: 30),
                  _buildActiveSessionWidget(context),
                ],
                const SizedBox(height: 30),
                const SizedBox(height: 30),
                _buildPopularGarageCard(context),
                const SizedBox(height: 30),
                _buildReservationCard(context),
              ],
            ),
          ),
          _DraggableChatbotButton(),
        ],
      ),
      bottomNavigationBar: FloatingCircularNavBar(currentPage: 'home'),
    );
  }

  Widget _buildReservationBox(BuildContext context) {
    final slotId = _reservedSlotId ?? "Unknown";
    final mallName = _reservedMallName ?? "Unknown location";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBanned && remainingBanTime > Duration.zero)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    "Unban in: ${remainingBanTime.inHours.toString().padLeft(2, '0')}:${(remainingBanTime.inMinutes % 60).toString().padLeft(2, '0')}:${(remainingBanTime.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            "Note: This reservation will be cancelled automatically after 30 minutes if not started.",
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.orangeAccent,
                size: 30,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "You have a reserved slot: $slotId in location: $mallName",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiveSessionPage(),
                      ),
                    );

                    if (mounted) {
                      await _checkActiveSession();
                    }
                  } catch (e, stackTrace) {
                    debugPrint("Error navigating to ActiveSessionPage: $e");
                    debugPrint(stackTrace.toString());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to open active session page."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Start Now"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isBanned) {
    return InkWell(
      onTap: () async {
        if (isBanned) {
          if (ScaffoldMessenger.maybeOf(context) != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "You cannot reserve slots because of your violations.",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          try {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          } catch (e, stackTrace) {
            debugPrint("Navigation to SearchPage failed: $e");
            debugPrint(stackTrace.toString());
            if (ScaffoldMessenger.maybeOf(context) != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Failed to open search page."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color:
              isBanned
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isBanned ? Colors.white38 : Colors.white70,
            ),
            const SizedBox(width: 10),
            Text(
              "List Parking Areas",
              style: TextStyle(
                color: isBanned ? Colors.white38 : Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(double screenHeight) {
    return Container(
      height: screenHeight * 0.23,
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF223344), Color(0xFF0F1E2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Text(
            "MY VEHICLE",
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
          Positioned(
            top: 20,
            child: Text(
              _defaultVehicleName.isNotEmpty
                  ? _defaultVehicleName
                  : "No vehicle selected",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(top: 65, left: 0, child: _buildVehicleImage()),
          Positioned(
            bottom: 0,
            right: 0,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditVehicle()),
                  );
                  await _refreshVehicle();
                } catch (e, stackTrace) {
                  debugPrint("Error while switching vehicle: $e");
                  debugPrint(stackTrace.toString());

                  if (ScaffoldMessenger.maybeOf(context) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Failed to switch vehicle. Please try again.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("SWITCH"),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build vehicle image with fallback error handling.
  Widget _buildVehicleImage() {
    try {
      if (_defaultVehicleImage.isNotEmpty) {
        return Image.asset(
          _defaultVehicleImage,
          width: 140,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Failed to load vehicle image: $error");
            return Image.asset(
              "assets/icons/car1.png",
              width: 140,
              height: 80,
              fit: BoxFit.contain,
            );
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Exception while loading vehicle image: $e");
      debugPrint(stackTrace.toString());
    }

    return Image.asset(
      "assets/icons/car1.png",
      width: 140,
      height: 80,
      fit: BoxFit.contain,
    );
  }

  Widget _buildReservationCard(BuildContext context) {
    final disableBooking = _hasActiveSession || _hasReservation || isBanned;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Reserve your favorite spot again!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_parking, color: Colors.white, size: 35),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "City Stars Mall",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Nasr City, Cairo",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      disableBooking
                          ? null
                          : () async {
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'selected_mall',
                                'City Stars Mall',
                              );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookSlotCSPage(),
                                ),
                              );
                            } catch (e, stackTrace) {
                              debugPrint("Error during booking navigation: $e");
                              debugPrint(stackTrace.toString());

                              if (ScaffoldMessenger.maybeOf(context) != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Failed to proceed to booking. Please try again.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        disableBooking ? Colors.grey : const Color(0xFFabdbe3),
                    foregroundColor: Colors.black,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Book Now >"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularGarageCard(BuildContext context) {
    final disableBooking = _hasActiveSession || _hasReservation || isBanned;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "The Most Popular Garage",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 35),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cairo Festival City Mall",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Ring Road, New Cairo",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      disableBooking
                          ? null
                          : () async {
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'selected_mall',
                                'Cairo Festival City Mall',
                              );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookSlotCfc(),
                                ),
                              );
                            } catch (e, stackTrace) {
                              debugPrint(
                                "Error during popular garage booking: $e",
                              );
                              debugPrint(stackTrace.toString());

                              if (ScaffoldMessenger.maybeOf(context) != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Failed to proceed to booking. Please try again.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        disableBooking ? Colors.grey : const Color(0xFFabdbe3),
                    foregroundColor: Colors.black,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Book Now >"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Active Session",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (!context.mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveSessionPage()),
                );

                await _checkActiveSession();
              } catch (e, stackTrace) {
                debugPrint("Error navigating to ActiveSessionPage: $e");
                debugPrint(stackTrace.toString());

                if (ScaffoldMessenger.maybeOf(context) != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Failed to open active session. Please try again.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFabdbe3),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Show Active Session"),
          ),
        ],
      ),
    );
  }
}
