// // // // // // //payment.dart LAST VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'package:frontend/pages/service/payment_storage.dart';

class PaymentPage extends StatefulWidget {
  final Duration? parkingDuration;
  final double? parkingCost;

  const PaymentPage({super.key, this.parkingDuration, this.parkingCost});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

enum PaymentMethod { creditCard, mobileWallet }

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;
  String? _checkoutUrl;
  String? _merchantOrderId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_merchantOrderId != null) {
        _showPaymentSuccessDialog(widget.parkingCost ?? 0);
      }
    }
  }

  Future<void> _startPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _checkoutUrl = null;
      _merchantOrderId = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final amount = widget.parkingCost ?? 0;

      final billingData = {
        "apartment": "NA",
        "email": user.email ?? "test@example.com",
        "floor": "NA",
        "first_name": user.displayName ?? "Garage",
        "street": "NA",
        "building": "NA",
        "phone_number": "01000000000",
        "shipping_method": "NA",
        "postal_code": "NA",
        "city": "NA",
        "country": "EG",
        "last_name": "EZway",
        "state": "NA",
      };

      final method =
          _selectedMethod == PaymentMethod.creditCard ? "card" : "wallet";

      final payload = {
        "amount": amount,
        "method": method,
        "billingData": billingData,
        "extras": {"userId": user.uid},
      };

      final response = await http.post(
        Uri.parse("http://garage.flash-ware.com:3000/payments/create-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to create payment: ${response.body}");
      }

      final data = jsonDecode(response.body);
      final checkoutUrl = data["checkoutUrl"] as String?;
      final merchantOrderId = data["merchant_order_id"] as String?;

      if (checkoutUrl == null || merchantOrderId == null) {
        throw Exception("Invalid response from server.");
      }

      setState(() {
        _checkoutUrl = checkoutUrl;
        _merchantOrderId = merchantOrderId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment link ready, please click to pay."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _openPaymentAndListen() async {
    if (_checkoutUrl == null || _merchantOrderId == null) return;

    final url = Uri.parse(_checkoutUrl!);

    final success = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open payment URL."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  Future<void> _waitForPaymentStatus(String merchantOrderId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("payments")
          .doc(merchantOrderId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Checking payment status..."),
          backgroundColor: Colors.teal,
        ),
      );

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment record not found."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = docSnapshot.data();
      if (data == null) return;

      final status = data["status"];

      if (status == "succeeded") {
        _showPaymentSuccessDialog(data["amount"]);
      } else if (status == "failed") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment failed."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment is still pending. Please wait."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error checking payment status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error checking payment status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentSuccessDialog(dynamic amount) async {
    final now = DateTime.now();
    final formattedDate = now.toIso8601String();

    final transaction = {
      "amount": amount ?? widget.parkingCost ?? 0,
      "method": _selectedMethod == PaymentMethod.creditCard ? "card" : "wallet",
      "createdAt": formattedDate,
    };

    await PaymentStorage.saveTransaction(transaction);

    final costText =
        (amount ?? widget.parkingCost)?.toStringAsFixed(2) ?? "N/A";

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.teal[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Payment Successful!",
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "You have paid $costText €",
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPayButton() {
    final label =
        _selectedMethod == PaymentMethod.creditCard
            ? "Pay with Your credit card"
            : "Pay with Your mobile wallet";

    return ElevatedButton.icon(
      icon: const Icon(Icons.payment),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isProcessing ? Colors.grey : Colors.orangeAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: _isProcessing ? null : _startPayment,
    );
  }

  Widget _buildLinkButton() {
    if (_checkoutUrl == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: _openPaymentAndListen,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
      child: const Text(
        "Pay with this link",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.credit_card,
            color:
                _selectedMethod == PaymentMethod.creditCard
                    ? Colors.tealAccent
                    : Colors.white,
          ),
          onPressed:
              () => setState(() => _selectedMethod = PaymentMethod.creditCard),
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: Icon(
            Icons.account_balance_wallet,
            color:
                _selectedMethod == PaymentMethod.mobileWallet
                    ? Colors.tealAccent
                    : Colors.white,
          ),
          onPressed:
              () =>
                  setState(() => _selectedMethod = PaymentMethod.mobileWallet),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Payment", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMethodToggle(),
            const SizedBox(height: 30),
            _buildPayButton(),
            const SizedBox(height: 20),
            _buildLinkButton(),
          ],
        ),
      ),
    );
  }
}
