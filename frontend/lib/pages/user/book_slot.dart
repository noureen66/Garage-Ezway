// //book_slot.dart LAST VERSION
import 'package:flutter/material.dart';
import 'package:frontend/pages/user/active_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/user/maquette_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/utils/utils_limitations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class BookSlotPage extends StatefulWidget {
  @override
  _BookSlotPageState createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  int currentFloor = 1;
  String? selectedSlotId;
  int? selectedFloor;
  final Duration reservationTimeout = Duration(minutes: 30);
  List<Map<String, dynamic>> firstFloorSpaces = [];
  List<Map<String, dynamic>> secondFloorSpaces = [];

  bool isBanned = false;
  String banReason = '';
  int unpaidAmount = 0;
  late StreamSubscription firstFloorSub;
  late StreamSubscription secondFloorSub;

  @override
  void initState() {
    super.initState();
    _loadSavedSlot();
    _setupSlotListeners();
    _checkBanStatus();
  }

  Future<void> _checkBanStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User not logged in properly.")));
      return;
    }

    final status = await checkBanStatus(userId);

    if (!mounted) return;
    setState(() {
      isBanned = status['isBanned'] ?? false;
      banReason = status['reason'] ?? '';
      unpaidAmount = status['unpaidAmount'] ?? 0;
    });
  }

  void _setupSlotListeners() {
    final dbRef = FirebaseDatabase.instance.ref();

    firstFloorSub = dbRef.child('parking/first_floor').onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (!mounted) return;
      setState(() {
        firstFloorSpaces =
            data.entries.map((entry) {
                final num = int.parse(entry.key.replaceAll('slot', ''));
                final status = entry.value['status'];
                return {
                  'id': 'A$num',
                  'status':
                      status == 'free'
                          ? 'Available'
                          : status == 'registered'
                          ? 'Reserved'
                          : status == 'occupied'
                          ? 'Occupied'
                          : 'Unknown',
                  'row': 'A',
                  'number': num,
                };
              }).toList()
              ..sort(
                (a, b) => (a['number']! as int).compareTo(b['number']! as int),
              );
      });
    });

    secondFloorSub = dbRef.child('parking/second_floor').onValue.listen((
      event,
    ) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (!mounted) return;
      setState(() {
        secondFloorSpaces =
            data.entries.map((entry) {
                final fullNum = int.parse(entry.key.replaceAll('slot', ''));
                final num = fullNum - 3;
                final status = entry.value['status'];
                return {
                  'id': 'D$num',
                  'status':
                      status == 'free'
                          ? 'Available'
                          : status == 'registered'
                          ? 'Reserved'
                          : status == 'occupied'
                          ? 'Occupied'
                          : 'Unknown',
                  'row': 'D',
                  'number': num,
                };
              }).toList()
              ..sort(
                (a, b) => (a['number']! as int).compareTo(b['number']! as int),
              );
      });
    });
  }

  @override
  void dispose() {
    firstFloorSub.cancel();
    secondFloorSub.cancel();
    super.dispose();
  }

  void toggleSlot(String slotId) {
    if (!mounted) return;
    setState(() {
      final currentSpaces =
          currentFloor == 1 ? firstFloorSpaces : secondFloorSpaces;

      if (selectedSlotId == slotId && selectedFloor == currentFloor) {
        for (var space in currentSpaces) {
          if (space['id'] == slotId && space['status'] == 'Selected') {
            space['status'] = 'Available';
          }
        }
        selectedSlotId = null;
        selectedFloor = null;
      } else {
        for (var space in firstFloorSpaces + secondFloorSpaces) {
          if (space['status'] == 'Selected') space['status'] = 'Available';
        }

        for (var space in currentSpaces) {
          if (space['id'] == slotId && space['status'] == 'Available') {
            space['status'] = 'Selected';
            selectedSlotId = slotId;
            selectedFloor = currentFloor;
          }
        }
      }
    });
  }

  Future<void> _loadSavedSlot() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('name') || !prefs.containsKey('email')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User information incomplete. Please re-login."),
        ),
      );
      return;
    }
    final savedSlot = prefs.getString('selected_slot_id');
    final savedFloor = prefs.getInt('selected_floor');
    final bookingTime = prefs.getString('booking_time');

    if (savedSlot != null && savedFloor != null && bookingTime != null) {
      final bt = DateTime.tryParse(bookingTime);
      if (bt != null && DateTime.now().difference(bt) < reservationTimeout) {
        if (!mounted) return;
        setState(() {
          selectedSlotId = savedSlot;
          selectedFloor = savedFloor;
          currentFloor = savedFloor;
          final targetSpaces =
              (savedFloor == 1) ? firstFloorSpaces : secondFloorSpaces;
          for (var space in targetSpaces) {
            if (space['id'] == savedSlot && space['status'] == 'Available') {
              space['status'] = 'Selected';
            }
          }
        });
      } else {
        prefs.remove('selected_slot_id');
        prefs.remove('selected_floor');
        prefs.remove('booking_time');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E2F), Color(0xFF1A2A3F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: _MainContent(
                  currentFloor: currentFloor,
                  spaces:
                      currentFloor == 1 ? firstFloorSpaces : secondFloorSpaces,
                  onFloorChanged: (floor) {
                    if (!mounted) return;
                    setState(() {
                      currentFloor = floor;
                    });
                  },
                  onSlotSelected: toggleSlot,
                  hasSelectedSlot: selectedSlotId != null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final int currentFloor;
  final List<Map<String, dynamic>> spaces;
  final Function(int) onFloorChanged;
  final Function(String) onSlotSelected;
  final bool hasSelectedSlot;

  _MainContent({
    required this.currentFloor,
    required this.spaces,
    required this.onFloorChanged,
    required this.onSlotSelected,
    required this.hasSelectedSlot,
  });

  @override
  Widget build(BuildContext context) {
    final String rowLetter = currentFloor == 1 ? 'A' : 'D';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed:
                    currentFloor > 1
                        ? () => onFloorChanged(currentFloor - 1)
                        : null,
                icon: Icon(
                  Icons.chevron_left,
                  color:
                      currentFloor > 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                ),
              ),
              Text(
                "${currentFloor}${currentFloor == 1 ? 'st' : 'nd'} Floor",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              IconButton(
                onPressed:
                    currentFloor < 2
                        ? () => onFloorChanged(currentFloor + 1)
                        : null,
                icon: Icon(
                  Icons.chevron_right,
                  color:
                      currentFloor < 2
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Align(
              alignment:
                  currentFloor == 1
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: currentFloor == 1 ? 20 : 0,
                  right: currentFloor == 2 ? 20 : 0,
                ),
                child: _VerticalParkingColumn(
                  rowLetter: rowLetter,
                  spaces: spaces,
                  onSlotSelected: onSlotSelected,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                hasSelectedSlot
                    ? () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        if (!prefs.containsKey('name') ||
                            !prefs.containsKey('email')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "User information incomplete. Please re-login.",
                              ),
                            ),
                          );
                          return;
                        }
                        Map<String, dynamic> selectedSlot;
                        try {
                          selectedSlot = spaces.firstWhere(
                            (slot) => slot["status"] == "Selected",
                          );
                        } catch (e) {
                          selectedSlot = <String, dynamic>{};
                        }

                        if (selectedSlot.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No slot selected.")),
                          );
                          return;
                        }
                        final slotId = selectedSlot["id"];
                        final user = FirebaseAuth.instance.currentUser;
                        final userId = user?.uid ?? 'unknown';
                        final now = DateTime.now();
                        final userDoc =
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get();
                        bool isBlacklisted = false;

                        if (userDoc.exists) {
                          final data = userDoc.data();
                          isBlacklisted = data?['isBlacklisted'] == true;
                        }
                        if (isBlacklisted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "🚫 You are blacklisted and cannot book slots.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final localBanReason = prefs.getString('banReason');
                        final localBannedUntil = prefs.getInt('bannedUntil');

                        if (localBanReason != null &&
                            localBannedUntil != null) {
                          final nowMs = DateTime.now().millisecondsSinceEpoch;
                          if (nowMs < localBannedUntil) {
                            final remaining = Duration(
                              milliseconds: localBannedUntil - nowMs,
                            );
                            final hours = remaining.inHours;
                            final minutes = remaining.inMinutes % 60;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "🚫 You are temporarily banned due to $localBanReason.\nTry again in $hours hours and $minutes minutes.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          } else {
                            await prefs.remove('banReason');
                            await prefs.remove('bannedUntil');
                          }
                        }

                        final floorName =
                            (currentFloor == 1)
                                ? 'first_floor'
                                : 'second_floor';
                        int numericSlotId;
                        try {
                          numericSlotId = int.parse(
                            slotId.replaceAll(RegExp(r'[^\d]'), ''),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Invalid slot ID format.")),
                          );
                          return;
                        }
                        String realSlotKey =
                            currentFloor == 1
                                ? 'slot$numericSlotId'
                                : 'slot${numericSlotId + 3}';

                        final dbRef = FirebaseDatabase.instance.ref();
                        await dbRef
                            .child('parking/$floorName/$realSlotKey')
                            .update({
                              'status': 'registered',
                              'reservedBy': userId,
                            });
                        final reservationData = {
                          'userId': userId,
                          'floor': floorName,
                          'slotId': realSlotKey,
                          'status': 'registered',
                          'timestamp': now,
                        };
                        try {
                          await FirebaseFirestore.instance
                              .collection('reservations')
                              .add(reservationData);
                          debugPrint(
                            " Reservation added to Firestore: $reservationData",
                          );
                        } catch (e) {
                          debugPrint("Firestore reservations write failed: $e");
                        }
                        final userDocRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId);
                        final snapshot = await userDocRef.get();
                        if (!snapshot.exists ||
                            snapshot.data()?['Reservation_history'] == null) {
                          try {
                            await userDocRef.set({
                              'Reservation_history': FieldValue.arrayUnion([
                                reservationData,
                              ]),
                            }, SetOptions(merge: true));
                            debugPrint(" Reservation history updated");
                          } catch (e) {
                            debugPrint(
                              " Firestore user history update failed: $e",
                            );
                          }
                        }
                        await userDocRef.set({
                          'Reservation_history': FieldValue.arrayUnion([
                            reservationData,
                          ]),
                        }, SetOptions(merge: true));
                        await prefs.setString('selected_slot_id', slotId);
                        await prefs.setInt('selected_floor', currentFloor);
                        await prefs.setString(
                          'booking_time',
                          now.toIso8601String(),
                        );
                        await prefs.setString('selected_mall', 'Maquette');
                        debugPrint(
                          " Saved booking: slotId=$slotId, floor=$currentFloor, booking_time=${now.toIso8601String()}",
                        );
                        await prefs.setBool('hasArrived', false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveSessionPage(),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error while booking slot: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'An error occurred while booking. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF46B1A1),
              disabledBackgroundColor: const Color(0xFF46B1A1).withOpacity(0.3),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "BOOK SELECTION",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MallDirectionsPage(
                        mallName: 'Maquette',
                        mallLocation: LatLng(30.0233, 31.5017),
                      ),
                ),
              );
            },
            child: const Text(
              'Get Directions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalParkingColumn extends StatelessWidget {
  final String rowLetter;
  final List<Map<String, dynamic>> spaces;
  final Function(String) onSlotSelected;

  _VerticalParkingColumn({
    required this.rowLetter,
    required this.spaces,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[700]!, width: 2),
          right: BorderSide(color: Colors.grey[700]!, width: 2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "Row $rowLetter",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: ClampingScrollPhysics(),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                return _ParkingSlot(
                  space: spaces[index],
                  onTap: () => onSlotSelected(spaces[index]['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkingSlot extends StatelessWidget {
  final Map<String, dynamic> space;
  final VoidCallback onTap;

  _ParkingSlot({required this.space, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = space['status'];
    final id = space['id'];
    Widget slotIcon;
    Color textColor = Colors.white;
    Color? backgroundColor;
    BoxBorder? border;

    if (status == 'Available') {
      slotIcon = Icon(
        Icons.directions_car_outlined,
        color: Colors.white,
        size: 50,
      );
      border = Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1));
    } else if (status == 'Selected') {
      slotIcon = Icon(Icons.directions_car, color: Colors.green, size: 50);
      textColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.15);
      border = Border.all(color: Colors.green, width: 1);
    } else if (status == 'Occupied') {
      slotIcon = Icon(Icons.directions_car, color: Colors.red, size: 50);
      textColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
      border = Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1));
    } else {
      slotIcon = Icon(Icons.directions_car, color: Colors.grey[400], size: 50);
      textColor = Colors.grey[400]!;
      border = Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1));
    }

    return GestureDetector(
      onTap: status == 'Available' || status == 'Selected' ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18),
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: status == 'Selected' ? BorderRadius.circular(8) : null,
          boxShadow:
              status == 'Selected'
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            slotIcon,
            SizedBox(height: 10),
            Text(
              id,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 6),
            Text(status, style: TextStyle(color: textColor, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
