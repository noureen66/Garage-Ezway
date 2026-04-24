// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
