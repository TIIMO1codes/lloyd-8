import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class OtpPage extends StatefulWidget {
  final VoidCallback onVerified;
  final String email;

  const OtpPage({
    super.key,
    required this.onVerified,
    required this.email,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final otpController = TextEditingController();
  String generatedOtp = "";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    sendOtp();
  }

  String generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  Future<void> sendOtp() async {
    generatedOtp = generateOtp();

    final smtpServer = gmail(
      "lloydaquino321@gmail.com",
      "eezr kjkj kbjy usba",
    );

    final message = Message()
      ..from = const Address(
          "YOUR_EMAIL@gmail.com", "OTP Verification")
      ..recipients.add(widget.email)
      ..subject = "Your OTP Code"
      ..text = "Your OTP code is: $generatedOtp";

    try {
      await send(message, smtpServer);
    } catch (e) {
      setState(() => errorMessage = "Failed to send OTP");
    }
  }

void verifyOtp() {
  if (otpController.text.trim() == generatedOtp) {
    widget.onVerified(); // 🔥 THIS WAS MISSING
  } else {
    setState(() => errorMessage = "Invalid OTP");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF01312D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "OTP Verification",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Enter OTP",
                    labelStyle:
                        const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor:
                        Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(
                        color: Colors.redAccent),
                  ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          const Color(0xFF72BF00),
                    ),
                    child: const Text(
                      "Verify OTP",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
