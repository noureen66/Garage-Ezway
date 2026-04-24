// // // // payment_and_cards.dart LAST VERSIOn
// ignore_for_file: unnecessary_cast
import 'package:frontend/pages/service/payment_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    try {
      final history = await PaymentStorage.getPaymentHistory();
      history.sort(
        (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
      );

      setState(() {
        _paymentHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching payment history: $e");
      setState(() {
        _paymentHistory = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final method = tx['method'] ?? 'unknown';
    final amount = tx['amount'] ?? 0;
    final createdAt = tx['createdAt'] ?? '';
    DateTime date;
    try {
      date = DateTime.parse(createdAt);
    } catch (_) {
      date = DateTime.now();
    }
    final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(date);

    final methodLabel = method == 'wallet' ? 'Mobile Wallet' : 'Credit Card';
    final icon =
        methodLabel == 'Mobile Wallet'
            ? Icons.account_balance_wallet
            : Icons.credit_card;
    final color =
        methodLabel == 'Mobile Wallet' ? Colors.deepOrange : Colors.teal;

    return Card(
      color: const Color(0xFF1A2A3A),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          methodLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Date: $formattedDate",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          "- $amount €",
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
              : ListView(
                children: [
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "Payment History",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                  if (_paymentHistory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "No payment history found.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    ..._paymentHistory.map(_buildTransactionItem).toList(),
                  const SizedBox(height: 20),
                ],
              ),
    );
  }
}
