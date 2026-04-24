// maquette_slots.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MaquetteSlotsPage extends StatefulWidget {
  const MaquetteSlotsPage({super.key});

  @override
  State<MaquetteSlotsPage> createState() => _MaquetteSlotsPageState();
}

class _MaquetteSlotsPageState extends State<MaquetteSlotsPage> {
  int currentFloor = 1;
  int carCount = 0;

  List<Map<String, dynamic>> firstFloorSpaces = [];
  List<Map<String, dynamic>> secondFloorSpaces = [];

  @override
  void initState() {
    super.initState();
    _setupSlotListeners();
  }

  void _setupSlotListeners() {
    final dbRef = FirebaseDatabase.instance.ref();

    dbRef.child('parking').onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      int occupiedCount = 0;

      List<Map<String, dynamic>> updatedFirstFloor = [];
      List<Map<String, dynamic>> updatedSecondFloor = [];

      data.forEach((floorKey, floorData) {
        final floorMap = Map<String, dynamic>.from(floorData);

        floorMap.forEach((slotKey, slotData) {
          final slotMap = Map<String, dynamic>.from(slotData);
          final status = slotMap['status'];
          final reservedBy = slotMap['reservedBy'];
          final slotNumber = int.parse(slotKey.replaceAll('slot', ''));

          if (status == 'occupied') {
            occupiedCount++;
          }

          final mappedSlot = {
            'id':
                floorKey == 'first_floor'
                    ? 'A$slotNumber'
                    : 'D${slotNumber - 3}',
            'status': _mapStatus(status),
            'row': floorKey == 'first_floor' ? 'A' : 'D',
            'number': floorKey == 'first_floor' ? slotNumber : (slotNumber - 3),
            'reservedBy': reservedBy,
          };

          if (floorKey == 'first_floor') {
            updatedFirstFloor.add(mappedSlot);
          } else if (floorKey == 'second_floor') {
            updatedSecondFloor.add(mappedSlot);
          }
        });
      });

      updatedFirstFloor.sort(
        (a, b) => (a['number'] as int).compareTo(b['number'] as int),
      );
      updatedSecondFloor.sort(
        (a, b) => (a['number'] as int).compareTo(b['number'] as int),
      );

      if (mounted) {
        setState(() {
          firstFloorSpaces = updatedFirstFloor;
          secondFloorSpaces = updatedSecondFloor;
          carCount = occupiedCount;
        });
      }
    });
  }

  String _mapStatus(String status) {
    return switch (status) {
      'free' => 'Available',
      'registered' => 'Reserved',
      'occupied' => 'Occupied',
      _ => 'Unknown',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rowLetter = currentFloor == 1 ? 'A' : 'D';
    final spaces = currentFloor == 1 ? firstFloorSpaces : secondFloorSpaces;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Maquette Slots (Admin)',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E2F), Color(0xFF1A2A3F)],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      currentFloor > 1
                          ? () => setState(() => currentFloor--)
                          : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: Colors.white.withOpacity(currentFloor > 1 ? 1 : 0.3),
                  ),
                ),
                Text(
                  "$currentFloor${currentFloor == 1 ? 'st' : 'nd'} Floor",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  onPressed:
                      currentFloor < 2
                          ? () => setState(() => currentFloor++)
                          : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(currentFloor < 2 ? 1 : 0.3),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: currentFloor == 1 ? 20 : 0,
                  right: currentFloor == 2 ? 20 : 0,
                  bottom: 12.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _VerticalParkingColumn(
                        rowLetter: rowLetter,
                        spaces: spaces,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Cars Parked: $carCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalParkingColumn extends StatelessWidget {
  final String rowLetter;
  final List<Map<String, dynamic>> spaces;

  const _VerticalParkingColumn({required this.rowLetter, required this.spaces});

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
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                return _ParkingSlot(space: spaces[index]);
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

  const _ParkingSlot({required this.space});
  String _determineFloor(String rowLetter) {
    if (rowLetter == 'A') return "first_floor";
    if (rowLetter == 'D') return "second_floor";
    return "unknown_floor";
  }

  String _determineSlotId(int number) {
    return "slot$number";
  }

  Future<void> _cancelReservation(BuildContext context) async {
    final id = space['id'];
    final row = space['row'];
    final number = space['number'];

    String _determineFloor(String rowLetter) {
      if (rowLetter == 'A') return "first_floor";
      if (rowLetter == 'D') return "second_floor";
      return "unknown_floor";
    }

    String _determineSlotId(int number) {
      return "slot$number";
    }

    final floor = _determineFloor(row);
    final slotId = _determineSlotId(number);

    if (floor == "unknown_floor") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unknown floor")));
      return;
    }

    try {
      // ✅ Get admin token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin token not found — please log in again."),
          ),
        );
        return;
      }

      final url = Uri.parse(
        "http://garage.flash-ware.com:3000/admin/remove-booking/$floor/$slotId",
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reservation cancelled successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel reservation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = space['status'];
    final id = space['id'];
    final reservedBy = space['reservedBy'];

    Icon icon;
    Color textColor = Colors.white;
    Color? backgroundColor;

    switch (status) {
      case 'Available':
        icon = const Icon(
          Icons.directions_car_outlined,
          color: Colors.white,
          size: 50,
        );
        break;
      case 'Reserved':
        icon = const Icon(Icons.directions_car, color: Colors.orange, size: 50);
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange;
        break;
      case 'Occupied':
        icon = const Icon(Icons.directions_car, color: Colors.red, size: 50);
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        icon = const Icon(Icons.directions_car, color: Colors.grey, size: 50);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            id,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(status, style: TextStyle(color: textColor, fontSize: 18)),
          if ((status == 'Reserved' || status == 'Occupied') &&
              reservedBy != null &&
              reservedBy != "null")
            Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'UID: $reservedBy',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (status == 'Reserved') ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _cancelReservation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Cancel the reservation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
