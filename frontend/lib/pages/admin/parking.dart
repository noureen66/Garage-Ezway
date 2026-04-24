import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/pages/admin/admin_home.dart';
import 'package:frontend/pages/admin/admin_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_parking.dart';

class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  String selectedItem = 'Parking';
  String parkingName = "Maquette";
  String parkingPrice = "20";
  String parkingLocation = "El Dokki, Giza";
  String parkingSlots = "5";
  String? parkingImagePath;

  @override
  void initState() {
    super.initState();
    _loadParkingData();
  }

  Future<void> _loadParkingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      parkingPrice = prefs.getString('parkingPrice') ?? parkingPrice;
      parkingLocation = prefs.getString('parkingLocation') ?? parkingLocation;
      parkingSlots = prefs.getString('parkingSlots') ?? parkingSlots;
      parkingImagePath = prefs.getString('parkingImagePath');
    });
  }

  Future<void> _saveParkingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parkingPrice', parkingPrice);
    await prefs.setString('parkingLocation', parkingLocation);
    await prefs.setString('parkingSlots', parkingSlots);
    if (parkingImagePath != null) {
      await prefs.setString('parkingImagePath', parkingImagePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AdminNavBar(currentPage: 'parking'),
      backgroundColor: const Color(0xFF25303B),
      body: RefreshIndicator(
        onRefresh: _loadParkingData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                ),
                child: _buildBackButton(context),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF000000).withOpacity(0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child:
                                  parkingImagePath != null
                                      ? Image.file(
                                        File(parkingImagePath!),
                                        fit: BoxFit.cover,
                                      )
                                      : Image.asset(
                                        'assets/icons/maquette.jpeg',
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parkingName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2C37),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey[300], height: 20),
                                _buildInfoRow(
                                  Icons.monetization_on,
                                  "PRICE PER HOUR:",
                                  "$parkingPrice LE/h",
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.location_on,
                                  "LOCATION:",
                                  parkingLocation,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.local_parking,
                                  "TOTAL SLOTS:",
                                  parkingSlots,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF1F2C37),
                        onPressed: () async {
                          final updatedData = await Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (_, __, ___) => EditParkingPage(
                                    name: parkingName,
                                    price: parkingPrice,
                                    location: parkingLocation,
                                    slots: parkingSlots,
                                    imagePath: parkingImagePath,
                                  ),
                              transitionsBuilder:
                                  (_, a, __, c) =>
                                      FadeTransition(opacity: a, child: c),
                            ),
                          );

                          if (updatedData != null) {
                            setState(() {
                              parkingPrice =
                                  updatedData["price"] ?? parkingPrice;
                              parkingLocation =
                                  updatedData["location"] ?? parkingLocation;
                              parkingSlots =
                                  updatedData["slots"] ?? parkingSlots;
                              parkingImagePath =
                                  updatedData["imagePath"] ?? parkingImagePath;
                            });
                            await _saveParkingData();
                            await _loadParkingData();
                          }
                        },
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const AdminHomePage(),
                  transitionsBuilder:
                      (_, a, __, c) => FadeTransition(opacity: a, child: c),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Parking Details",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1F2C37)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2C37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
