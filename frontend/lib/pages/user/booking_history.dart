// //booking_history.dart LAST VERSION
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/pages/model/booking.dart';
import 'package:frontend/pages/service/booking_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nave_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Booking> bookings = [];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        bookings = [];
      });
      return;
    }

    final history = await BookingStorage.getBookingHistoryForUser(user.uid);

    setState(() {
      bookings = history;
    });
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy – h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "GARAGE ",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: "EZway",
                style: GoogleFonts.dancingScript(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 15,
              left: 10,
              right: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Booking History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child:
                bookings.isEmpty
                    ? const Center(
                      child: Text(
                        'No bookings yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.local_parking,
                            color: Colors.teal,
                          ),
                          title: Text(
                            'Location: ${b.location}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${formatTime(b.time)}\nTotal: \$${b.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: const FloatingCircularNavBar(currentPage: ''),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
