//ticket.dart
// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment.dart';

import 'package:google_fonts/google_fonts.dart';

class ParkingReceiptScreen extends StatefulWidget {
  final Duration parkingDuration;
  final double parkingCost;
  final double pricePerHour;

  const ParkingReceiptScreen({
    Key? key,
    required this.parkingDuration,
    required this.parkingCost,
    required this.pricePerHour,
  }) : super(key: key);

  @override
  _ParkingReceiptScreenState createState() => _ParkingReceiptScreenState();
}

class _ParkingReceiptScreenState extends State<ParkingReceiptScreen> {
  String slotDisplay = "A3, Floor 1";
  String mallName = "Mall of Egypt Parking";

  @override
  void initState() {
    super.initState();
    _loadSlotAndMall();
  }

  Future<void> _loadSlotAndMall() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSlot = prefs.getString('selected_slot_id') ?? "A3";
    final savedFloor = prefs.getInt('selected_floor') ?? 1;
    final savedMall =
        prefs.getString('selected_mall') ?? "Mall of Egypt Parking";

    setState(() {
      slotDisplay = "$savedSlot, Floor $savedFloor";
      mallName = savedMall;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime startTime = now.subtract(widget.parkingDuration);
    final DateTime endTime = now;

    String formatDateTime(DateTime dt) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} "
          "${dt.day}/${dt.month}/${dt.year}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
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

        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'TICKET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "PARKING RECEIPT",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "${now.day}/${now.month}/${now.year}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_parking,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mallName,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "FROM : ${formatDateTime(startTime)}",
                        style: TextStyle(color: Colors.grey[300], fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "TO : ${formatDateTime(endTime)}",
                        style: TextStyle(color: Colors.grey[300], fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "SLOT : $slotDisplay",
                        style: TextStyle(color: Colors.grey[300], fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "PARKING TIME: ${_formatDuration(widget.parkingDuration)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "PRICE: ${widget.parkingCost.toStringAsFixed(2)} €",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PaymentPage(
                            parkingDuration: widget.parkingDuration,
                            parkingCost: widget.parkingCost,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 50,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 10,
                  shadowColor: Colors.tealAccent.withOpacity(0.4),
                ),
                child: const Text(
                  "Pay",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
