// //book_slot_moa.dart FINAL VERSION
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'active_session.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/pages/user/moa_map.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_fonts/google_fonts.dart';

class BookSlotMOAPage extends StatefulWidget {
  const BookSlotMOAPage({super.key});

  @override
  _BookSlotMOAPageState createState() => _BookSlotMOAPageState();
}

class _BookSlotMOAPageState extends State<BookSlotMOAPage> {
  int currentFloor = 1;
  String? selectedSlotId;
  int? selectedFloor;
  final Duration reservationTimeout = Duration(minutes: 30);

  final List<Map<String, dynamic>> firstFloorSpaces = [
    {"id": "A1", "status": "Available", "row": "A"},
    {"id": "A2", "status": "Reserved", "row": "A"},
    {"id": "A3", "status": "Occupied", "row": "A"},
    {"id": "A4", "status": "Available", "row": "A"},
    {"id": "A5", "status": "Reserved", "row": "A"},
    {"id": "A6", "status": "Available", "row": "A"},
    {"id": "A7", "status": "Occupied", "row": "A"},
    {"id": "A8", "status": "Occupied", "row": "A"},
    {"id": "B1", "status": "Available", "row": "B"},
    {"id": "B2", "status": "Available", "row": "B"},
  ];

  final List<Map<String, dynamic>> secondFloorSpaces = [
    {"id": "C1", "status": "Reserved", "row": "C"},
    {"id": "C2", "status": "Occupied", "row": "C"},
    {"id": "C3", "status": "Available", "row": "C"},
    {"id": "C4", "status": "Reserved", "row": "C"},
    {"id": "C5", "status": "Occupied", "row": "C"},
    {"id": "C6", "status": "Reserved", "row": "C"},
    {"id": "C7", "status": "Occupied", "row": "C"},
    {"id": "C8", "status": "Reserved", "row": "C"},
    {"id": "D1", "status": "Available", "row": "D"},
    {"id": "D2", "status": "Reserved", "row": "D"},
    {"id": "D3", "status": "Occupied", "row": "D"},
    {"id": "D4", "status": "Available", "row": "D"},
    {"id": "D5", "status": "Reserved", "row": "D"},
    {"id": "D6", "status": "Occupied", "row": "D"},
    {"id": "D7", "status": "Available", "row": "D"},
    {"id": "D8", "status": "Reserved", "row": "D"},
  ];

  void toggleSlot(String slotId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final currentSpaces =
          currentFloor == 1 ? firstFloorSpaces : secondFloorSpaces;

      if (selectedSlotId == slotId && selectedFloor == currentFloor) {
        for (var space in currentSpaces) {
          if (space["id"] == slotId && space["status"] == "Selected") {
            space["status"] = "Available";
            selectedSlotId = null;
            selectedFloor = null;
            prefs.remove('selected_slot_id');
            prefs.remove('selected_floor');
            prefs.remove('booking_time');
            break;
          }
        }
      } else {
        if (selectedSlotId != null) {
          final previousSpaces =
              selectedFloor == 1 ? firstFloorSpaces : secondFloorSpaces;
          for (var space in previousSpaces) {
            if (space["id"] == selectedSlotId &&
                space["status"] == "Selected") {
              space["status"] = "Available";
              break;
            }
          }
        }

        for (var space in currentSpaces) {
          if (space["id"] == slotId && space["status"] == "Available") {
            space["status"] = "Selected";
            selectedSlotId = slotId;
            selectedFloor = currentFloor;
            prefs.setString('selected_slot_id', selectedSlotId!);
            prefs.setInt('selected_floor', selectedFloor!);
            break;
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSlot();
  }

  Future<void> _loadSavedSlot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSlot = prefs.getString('selected_slot_id');
    final savedFloor = prefs.getInt('selected_floor');
    final bookingTimeStr = prefs.getString('booking_time');

    if (savedSlot != null && savedFloor != null && bookingTimeStr != null) {
      final bookingTime = DateTime.tryParse(bookingTimeStr);
      final now = DateTime.now();

      if (bookingTime != null &&
          now.difference(bookingTime) < reservationTimeout) {
        setState(() {
          selectedSlotId = savedSlot;
          selectedFloor = savedFloor;
          currentFloor = savedFloor;

          final targetSpaces =
              savedFloor == 1 ? firstFloorSpaces : secondFloorSpaces;

          for (var space in targetSpaces) {
            if (space["id"] == savedSlot && space["status"] == "Available") {
              space["status"] = "Selected";
              break;
            }
          }
        });
      } else {
        await prefs.remove('selected_slot_id');
        await prefs.remove('selected_floor');
        await prefs.remove('booking_time');
      }
    }
  }

  void _openGoogleMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=30.006980759392427,30.975465237434644&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaces = currentFloor == 1 ? firstFloorSpaces : secondFloorSpaces;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        title: Text(
          'Book Slot - Floor $currentFloor',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
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
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    currentFloor > 1
                        ? () => setState(() => currentFloor--)
                        : null,
              ),
              Text(
                'Floor $currentFloor',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    currentFloor < 2
                        ? () => setState(() => currentFloor++)
                        : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _VerticalParkingColumn(
              rowLetter: '',
              spaces: spaces,
              onSlotSelected: toggleSlot,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed:
                  selectedSlotId != null
                      ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'selected_slot_id',
                          selectedSlotId!,
                        );
                        await prefs.setInt('selected_floor', currentFloor);
                        await prefs.setString(
                          'booking_time',
                          DateTime.now().toIso8601String(),
                        );
                        await prefs.setString(
                          'selected_mall',
                          'Mall Of Arabia',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveSessionPage(),
                          ),
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46B1A1),
                disabledBackgroundColor: const Color(
                  0xFF46B1A1,
                ).withOpacity(0.3),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.directions_car, color: Colors.white),
              label: const Text(
                "BOOK SELECTION",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MallDirectionsPage(
                        mallName: 'Mall Of Arabia',
                        mallLocation: const LatLng(
                          30.006980759392427,
                          30.975465237434644,
                        ),
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
    final rows = spaces.map((e) => e['row']).toSet().toList()..sort();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          rows.map((row) {
            final rowSpaces = spaces.where((s) => s['row'] == row).toList();
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Row $row",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rowSpaces.length,
                        itemBuilder: (context, index) {
                          return _ParkingSlot(
                            space: rowSpaces[index],
                            onTap: () => onSlotSelected(rowSpaces[index]['id']),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
