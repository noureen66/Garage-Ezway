// File: book_slot_cs.dart FINAL VERSION
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'active_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class MallDirectionsPage extends StatefulWidget {
  final String mallName;
  final LatLng mallLocation;

  const MallDirectionsPage({
    super.key,
    required this.mallName,
    required this.mallLocation,
  });

  @override
  State<MallDirectionsPage> createState() => _MallDirectionsPageState();
}

class _MallDirectionsPageState extends State<MallDirectionsPage> {
  late GoogleMapController _mapController;

  void _openGoogleMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.mallLocation.latitude},${widget.mallLocation.longitude}&travelmode=driving';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        title: Text(
          'Directions to ${widget.mallName}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.mallLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('mall'),
                  position: widget.mallLocation,
                  infoWindow: InfoWindow(title: widget.mallName),
                ),
              },
              myLocationEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46B1A1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text(
                'Get Directions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              onPressed: _openGoogleMaps,
            ),
          ),
        ],
      ),
    );
  }
}

class BookSlotCSPage extends StatefulWidget {
  const BookSlotCSPage({super.key});

  @override
  _BookSlotCSPageState createState() => _BookSlotCSPageState();
}

class _BookSlotCSPageState extends State<BookSlotCSPage> {
  int currentFloor = 1;
  String? selectedSlotId;
  int? selectedFloor;
  final Duration reservationTimeout = Duration(minutes: 30);
  final List<Map<String, dynamic>> firstFloorSpaces = [
    {"id": "A1", "status": "Available", "row": "A"},
    {"id": "A2", "status": "Occupied", "row": "A"},
    {"id": "A3", "status": "Reserved", "row": "A"},
    {"id": "B1", "status": "Available", "row": "B"},
    {"id": "B2", "status": "Available", "row": "B"},
    {"id": "B3", "status": "Reserved", "row": "B"},
  ];
  final List<Map<String, dynamic>> secondFloorSpaces = [
    {"id": "D1", "status": "Available", "row": "D"},
    {"id": "D2", "status": "Available", "row": "D"},
    {"id": "C1", "status": "Reserved", "row": "C"},
    {"id": "C2", "status": "Occupied", "row": "C"},
    {"id": "C3", "status": "Occupied", "row": "C"},
    {"id": "C4", "status": "Reserved", "row": "C"},
    {"id": "C5", "status": "Available", "row": "C"},
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
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'selected_slot_id',
                        (spaces.firstWhere(
                          (slot) => slot["status"] == "Selected",
                        ))["id"],
                      );
                      await prefs.setInt('selected_floor', currentFloor);
                      await prefs.setString(
                        'booking_time',
                        DateTime.now().toIso8601String(),
                      );
                      await prefs.setString('selected_mall', 'City Stars Mall');

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
                        mallName: 'City Stars Mall',
                        mallLocation: const LatLng(
                          30.073609726221303,
                          31.347241706670346,
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
