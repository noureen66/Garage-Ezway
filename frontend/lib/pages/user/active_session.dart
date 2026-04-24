// File: active_session.dart FINAL VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'ticket.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/pages/model/booking.dart';
import 'package:frontend/pages/service/booking_storage.dart';
import 'package:frontend/pages/service/payment_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveSessionPage extends StatefulWidget {
  const ActiveSessionPage({super.key});

  @override
  _ActiveSessionPageState createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends State<ActiveSessionPage> {
  Timer? _timer;
  Duration _duration = const Duration();
  bool _isParkingActive = false;
  DateTime? _startTime;

  String? _slotId;
  int? _floor;

  Duration _reservationRemaining = const Duration();
  Timer? _reservationTimer;
  DateTime? _bookingTime;

  bool isBanned = false;
  String banReason = '';
  int unpaidAmount = 0;
  DateTime? banStartTime;
  Timer? banTimer;
  Duration remainingBanTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
    _loadSlotData();
    _checkBanStatus();
    _listenToSlotStatus();
  }

  void _listenToSlotStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selected_slot_id');
    final floor = prefs.getInt('selected_floor');

    if (id == null || floor == null) return;

    final floorName = floor == 1 ? 'first_floor' : 'second_floor';
    final num = int.tryParse(id.substring(1));
    final index = (floor == 1) ? 'slot$num' : 'slot${num! + 3}';

    final dbRef = FirebaseDatabase.instance.ref(
      'parking/$floorName/$index/status',
    );

    dbRef.onValue.listen((event) async {
      final status = event.snapshot.value;
      debugPrint("Slot status changed: $status");
      if (status == 'free' && _isParkingActive) {
        await _endParking(autoEnded: true);
      }
    });
  }

  Future<void> _checkBanStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final isBlacklistedFirestore = userDoc.data()?['isBlacklisted'] ?? false;

      if (isBlacklistedFirestore) {
        setState(() {
          isBanned = true;
          banReason = "Your session exceeded 24 hours. Please pay to unblock.";
        });
        return;
      }
    }

    final isBannedLocal = prefs.getBool('is_banned') ?? false;
    String? banStartStr = prefs.getString('ban_start_time');

    if (isBannedLocal && banStartStr != null) {
      final banStart = DateTime.tryParse(banStartStr);
      if (banStart != null) {
        final difference = DateTime.now().difference(banStart);
        if (difference < const Duration(hours: 24)) {
          setState(() {
            isBanned = true;
            banReason =
                "You reserved too many times without starting a session.";
            banStartTime = banStart;
          });
        } else {
          await prefs.setBool('is_banned', false);
          await prefs.remove('ban_start_time');
          await prefs.setInt('bad_reservations', 0);
          setState(() {
            isBanned = false;
            banReason = '';
          });
        }
      }
    }
  }

  Future<void> _checkActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStart = prefs.getString('parking_start_time');
    final hasActive = prefs.getBool('hasArrived') ?? false;

    if (savedStart != null) {
      _startTime = DateTime.tryParse(savedStart);
      if (_startTime != null) {
        _isParkingActive = true;
        _startBackgroundTimer();
      }
    } else if (hasActive) {
      debugPrint("Auto-starting session because hasActive is true.");
      await _startParking(auto: true);
    } else {
      final bookingTimeString = prefs.getString('booking_time');
      debugPrint("Booking time string from prefs: $bookingTimeString");
      if (bookingTimeString == null) {
        debugPrint("booking_time is NULL!");
      }
      if (bookingTimeString != null) {
        final bookingTime = DateTime.tryParse(bookingTimeString);
        if (bookingTime != null) {
          _bookingTime = bookingTime;
          final now = DateTime.now();
          final endTime = _bookingTime!.add(const Duration(minutes: 30));
          final remaining = endTime.difference(now);

          if (remaining.isNegative) {
            await prefs.remove('selected_slot_id');
            await prefs.remove('selected_floor');
            await prefs.remove('booking_time');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking expired after 30 minutes.'),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else {
            if (mounted) {
              setState(() {
                _reservationRemaining = remaining;
              });
            }
            _startReservationCountdownTimer();
          }
        }
      }
    }
  }

  Future<void> _startParking({bool auto = false}) async {
    _startTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'parking_start_time',
      _startTime!.toIso8601String(),
    ); //Stores this time in local storage
    if (!auto) {
      // defaults to false

      await prefs.setBool('hasArrived', true);
    }
    //Clear booking and reset reservations
    await prefs.remove('booking_time');
    prefs.setInt('bad_reservations', 0);

    //Get the current logged-in Firebase user
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final floorName = _floor == 1 ? 'first_floor' : 'second_floor';

    //Update slot status in Realtime Database
    if (_slotId != null && _floor != null) {
      final dbRef = FirebaseDatabase.instance.ref();
      final num = int.tryParse(
        _slotId!.substring(1),
      ); //Parse slot number from slotId
      final index = (_floor == 1) ? 'slot$num' : 'slot${num! + 3}';

      // Change slot status to "free" when parking starts
      await dbRef.child('parking/$floorName/$index').update({'status': 'free'});
    }
    //Update user session history in Firestore
    if (userId != null) {
      String realSlotKey;
      if (_floor == 1) {
        final num = int.parse(_slotId!.substring(1));
        realSlotKey = 'slot$num';
      } else {
        final num = int.parse(_slotId!.substring(1));
        realSlotKey = 'slot${num + 3}';
      }

      final sessionEntry = {
        'slotId': realSlotKey,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': 'active',
      };
      //Add this entry to Sessions_history array in the user’s Firestore document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'Sessions_history': FieldValue.arrayUnion([sessionEntry]),
      });
      //Save session info in SharedPreferences
      await prefs.setString('floor', floorName);
      await prefs.setString('mall', 'Maquette');
      await prefs.setString('city', 'Cairo');
      await prefs.setDouble('pricePerHour', 20.0);
      await prefs.setString('startTime', _startTime!.toIso8601String());
      await prefs.setString('session_status', 'active');
    }
    // Update UI state to indicate that parking is active
    setState(() {
      _isParkingActive = true;
    });

    _startBackgroundTimer();

    if (!auto) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Parking session started.")));
    }
  }

  void _startReservationCountdownTimer() {
    _reservationTimer?.cancel();
    _reservationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final endTime = _bookingTime!.add(const Duration(minutes: 30));
      final remaining = endTime.difference(now);

      //if time is over
      if (remaining.isNegative) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reservation expired.')));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() {
            _reservationRemaining = remaining;
          });
        }
      }
    });
  }

  //load selected slot and floor from local storage
  Future<void> _loadSlotData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('selected_slot_id');
    final floor = prefs.getInt('selected_floor');
    debugPrint(" Loaded slot data: slotId=$id, floor=$floor");

    if (id == null) {
      debugPrint(" selected_slot_id is NULL!");
    }
    if (floor == null) {
      debugPrint(" selected_floor is NULL!");
    }

    setState(() {
      _slotId = id;
      _floor = floor;
    });
  }

  void _startBackgroundTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(_startTime!);
      });
    });
  }

  Future<void> _endParking({bool autoEnded = false}) async {
    _timer?.cancel(); //stops timer
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('parking_start_time'); //clears stored start time
    if (_slotId != null && _floor != null) {
      final dbRef = FirebaseDatabase.instance.ref();
      final floorName = _floor == 1 ? 'first_floor' : 'second_floor';
      final num = int.tryParse(_slotId!.substring(1));
      final index = (_floor == 1) ? 'slot$num' : 'slot${num! + 3}';

      //sets slot status in firebase
      await dbRef.child('parking/$floorName/$index').set({
        'status': 'free',
        'reservedBy': 'null',
      });
    }
    //calculates cost
    final sessionDuration = DateTime.now().difference(_startTime!);
    final cost = _calculateCost(sessionDuration);
    final durationFormatted = _formatDuration(sessionDuration);

    //saves transaction in local payment storage
    await PaymentStorage.saveTransaction({
      'method': 'wallet',
      'amount': cost,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    //updates firesore session history
    if (userId != null) {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final userDoc = await userDocRef.get();

      final List<dynamic> sessions = userDoc.data()?['Sessions_history'] ?? [];

      if (sessions.isNotEmpty) {
        final lastSession = Map<String, dynamic>.from(sessions.last);
        lastSession['duration'] = durationFormatted;

        sessions.removeLast();
        sessions.add(lastSession);

        await userDocRef.update({'Sessions_history': sessions});
        //adds the records in sessions collection
        await FirebaseFirestore.instance.collection('sessions').add({
          'userid': userId,
          'slotId': lastSession['slotId'],
          'duration': durationFormatted,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
    //stores sessions locally
    final mallName = prefs.getString('selected_mall') ?? 'Unknown Mall';

    await prefs.setString('session_duration', durationFormatted);
    await prefs.setDouble('session_cost', cost);
    await prefs.setString('session_end_time', DateTime.now().toIso8601String());
    await prefs.setString('session_status', 'ended');

    if (user != null) {
      //saves bookings using BookingStorage helper
      await BookingStorage.addBooking(
        Booking(
          time: DateTime.now(),
          location: "$mallName – Floor $_floor, Slot $_slotId",
          amount: cost,
          userId: user.uid,
        ),
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ParkingReceiptScreen(
                parkingDuration: sessionDuration,
                parkingCost: cost,
                pricePerHour: 20.0,
              ),
        ),
      );
    }
  }

  double _calculateCost(Duration duration) {
    final hours = duration.inMinutes / 60;
    final roundedHours = hours.ceil();
    if (roundedHours < 1) {
      return 20.0;
    }
    return roundedHours * 20.0;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes % 60)}:${twoDigits(duration.inSeconds % 60)}";
  }

  String _formattedStartTime() {
    if (_startTime == null) return '';
    return "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')} ${_startTime!.day}/${_startTime!.month}/${_startTime!.year}";
  }

  //prevent memory leaks when widget is destroyed
  @override
  void dispose() {
    _timer?.cancel();
    _reservationTimer?.cancel();
    banTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      children: const [
                        Icon(Icons.block, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Banned",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banReason,
                      style: const TextStyle(color: Colors.white70),
                    ),

                    if (unpaidAmount > 0)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('payment_completed', true);
                          await prefs.setInt('unpaid_amount', 0);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update({'isBlacklisted': false});

                          setState(() {
                            isBanned = false;
                            unpaidAmount = 0;
                            banReason = '';
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Payment successful. Unbanned."),
                              backgroundColor: Colors.green,
                            ),
                          );
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
            const SizedBox(height: 10),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "GARAGE ",
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: "EZway",
                      style: GoogleFonts.dancingScript(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isParkingActive
                        ? "Parking Duration"
                        : "Reservation Time Remaining",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isParkingActive
                        ? _formatDuration(_duration)
                        : _formatDuration(_reservationRemaining),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Parking Details",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white38),
                  if (_startTime != null)
                    Text(
                      _formattedStartTime(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  Text(
                    "Slot:   ${_slotId ?? '-'}, Floor ${_floor ?? '-'}",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Text(
                    "City:   Cairo",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Text(
                    "Price per hour:   20€",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child:
                  !_isParkingActive
                      ? ElevatedButton(
                        onPressed:
                            isBanned
                                ? null
                                : () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('hasArrived', true);
                                  await _startParking(auto: false);
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: const Text(
                          "Start Parking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),
            if (!_isParkingActive && _bookingTime != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final user = FirebaseAuth.instance.currentUser;
                    final userId = user?.uid;
                    int badReservations = prefs.getInt('bad_reservations') ?? 0;
                    badReservations += 1;
                    await prefs.setInt('bad_reservations', badReservations);
                    if (badReservations >= 5) {
                      await prefs.setBool('is_banned', true);
                      await prefs.setString(
                        'ban_start_time',
                        DateTime.now().toIso8601String(),
                      );
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set({
                            'isBlacklisted': true,
                          }, SetOptions(merge: true));

                      if (mounted) {
                        setState(() {
                          isBanned = true;
                          banReason =
                              "You reserved too many times without starting a session.";
                          remainingBanTime = const Duration(hours: 24);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You have been banned for repeated misuse.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    if (_slotId != null && _floor != null) {
                      final dbRef = FirebaseDatabase.instance.ref();
                      final level =
                          _floor == 1 ? 'first_floor' : 'second_floor';
                      final num = int.tryParse(_slotId!.substring(1));
                      final index =
                          (_floor == 1) ? 'slot$num' : 'slot${num! + 3}';
                      await dbRef.child('parking/$level/$index').set({
                        'status': 'free',
                        'reservedBy': 'null',
                      });
                    }

                    await prefs.remove('selected_slot_id');
                    await prefs.remove('selected_floor');
                    await prefs.remove('booking_time');

                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Your reservation has been cancelled."),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: const Text(
                    "Cancel Reservation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
