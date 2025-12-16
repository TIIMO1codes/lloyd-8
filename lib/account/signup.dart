import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String errorMessage = "";

  Future<void> signUp() async {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final username = usernameController.text.trim();
    final pass = passwordController.text.trim();

    if (first.isEmpty || last.isEmpty || username.isEmpty || pass.isEmpty) {
      setState(() => errorMessage = "Please fill all fields.");
      return;
    }

    try {
      // Check if username already exists
      final existing = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() => errorMessage = "Username already taken.");
        return;
      }

      // Save user to Firestore
      await FirebaseFirestore.instance.collection("users").add({
        "firstName": first,
        "lastName": last,
        "username": username,
        "password": pass,
        "createdAt": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      setState(() => errorMessage = "Signup failed: $e");
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
                  "Create Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Fields
                buildField("First Name", firstNameController),
                const SizedBox(height: 15),
                buildField("Last Name", lastNameController),
                const SizedBox(height: 15),
                buildField("Username", usernameController),
                const SizedBox(height: 15),
                buildField("Password", passwordController, obscure: true),

                const SizedBox(height: 10),

                if (errorMessage.isNotEmpty)
                  Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF72BF00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Create Account", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
