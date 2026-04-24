// //edit_vehicle.dart LAST VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/user/add_vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nave_bar.dart';

class EditVehicle extends StatefulWidget {
  const EditVehicle({super.key});

  @override
  _EditVehiclePageState createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehicle> {
  List<Map<String, dynamic>> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesString = prefs.getString('vehicles');
    if (vehiclesString != null) {
      final List<dynamic> decoded = jsonDecode(vehiclesString);
      setState(() {
        vehicles =
            decoded
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
      });
    } else {
      vehicles = [
        {
          "name": "Toyota Camry",
          "image": "assets/icons/car1.png",
          "isDefault": false,
          "plateNumber": "1234",
        },
        {
          "name": "Honda Civic",
          "image": "assets/icons/car2.png",
          "isDefault": false,
          "plateNumber": "5678",
        },
      ];
      await _saveVehicles();
      setState(() {});
    }
  }

  Future<void> _saveVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(vehicles);
    await prefs.setString('vehicles', encoded);

    final defaultVehicle = vehicles.firstWhere(
      (v) => v["isDefault"] == true,
      orElse: () => {},
    );
    if (defaultVehicle.isNotEmpty) {
      await prefs.setString(
        'default_vehicle_name',
        defaultVehicle['name'] ?? "No vehicle selected",
      );
    } else {
      await prefs.setString('default_vehicle_name', "No vehicle selected");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'vehicles': vehicles},
      );
    }
  }

  Future<void> setDefaultVehicle(int index) async {
    setState(() {
      for (int i = 0; i < vehicles.length; i++) {
        vehicles[i]["isDefault"] = i == index;
      }
    });
    await _saveVehicles();
  }

  Future<void> deleteVehicle(int index) async {
    bool wasDefault = vehicles[index]["isDefault"] ?? false;
    setState(() {
      vehicles.removeAt(index);
      if (wasDefault && vehicles.isNotEmpty) {
        vehicles[0]["isDefault"] = true;
      }
    });
    await _saveVehicles();
  }

  void navigateToAddVehiclePage() async {
    final newCar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehiclePage()),
    );

    if (newCar != null && newCar is Map<String, dynamic>) {
      setState(() {
        vehicles.add({
          "name": newCar['name'],
          "image": newCar['image'] ?? "assets/icons/car1.png",
          "isDefault": false,
          "plateNumber": newCar['plateNumber'] ?? "0000",
        });
      });
      await _saveVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 15, 30, 47),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildBackButton(),
            const SizedBox(height: 20),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No vehicles found. Please add a vehicle.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ...vehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final car = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: _buildVehicleCard(
                  car["name"] ?? "",
                  car["image"] ?? "assets/icons/car1.png",
                  car["isDefault"] ?? false,
                  car["plateNumber"] ?? "0000",
                  index,
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: const FloatingCircularNavBar(currentPage: ''),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Text(
            "Switch car",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: navigateToAddVehiclePage,
            child: const CircleAvatar(
              backgroundColor: Colors.teal,
              radius: 18,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
    String carName,
    String imagePath,
    bool isDefault,
    String plateNumber,
    int index,
  ) {
    return GestureDetector(
      onTap: () => setDefaultVehicle(index),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Vehicle",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  carName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Plate: $plateNumber",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    height: 140,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 10),
                if (isDefault)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "Default",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text(
                        'Remove Vehicle',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to remove this car?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await deleteVehicle(index);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
