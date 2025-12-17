import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? firstNameError;
  String? lastNameError;
  String? usernameError;
  String? emailError;
  String? passwordError;

  bool isLoading = false;

  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // ---------- VALIDATORS ----------
  bool _isValidName(String v) => RegExp(r'^[A-Za-z]+$').hasMatch(v);

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v);

  bool _isStrongPassword(String v) =>
      RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$').hasMatch(v);

  // ---------- OTP ----------
  String _generateOtp() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  // ---------- SEND OTP EMAIL ----------
  Future<void> _sendOtpToEmail(String toEmail, String otp) async {
    const String gmailEmail = 'lloydaquino321@gmail.com';
    const String gmailAppPassword = 'eezrkjkjkbjyusba';

    final smtpServer = gmail(gmailEmail, gmailAppPassword);

    final message = Message()
      ..from = Address(gmailEmail, 'OTP Service')
      ..recipients.add(toEmail)
      ..subject = 'Your OTP Code'
      ..text = '''
Hello,

Your OTP Code is: $otp

This OTP does NOT expire.

If you did not request this, please ignore this email.
''';

    await send(message, smtpServer);
  }

  // ---------- SIGN UP ----------
  Future<void> signUp() async {
    if (isLoading) return;

    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final pass = passwordController.text;

    setState(() {
      firstNameError = null;
      lastNameError = null;
      usernameError = null;
      emailError = null;
      passwordError = null;
    });

    bool hasError = false;

    if (first.isEmpty || !_isValidName(first)) {
      firstNameError = "First name must contain letters only.";
      hasError = true;
    }

    if (last.isEmpty || !_isValidName(last)) {
      lastNameError = "Last name must contain letters only.";
      hasError = true;
    }

    if (username.isEmpty) {
      usernameError = "Username is required.";
      hasError = true;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      emailError = "Enter a valid email.";
      hasError = true;
    }

    if (pass.isEmpty || !_isStrongPassword(pass)) {
      passwordError =
          "Min 8 chars, 1 uppercase, 1 number, 1 special character.";
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔍 USERNAME UNIQUE
      final usernameCheck = await users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        setState(() {
          usernameError = "Username already taken.";
          isLoading = false;
        });
        return;
      }

      // 🔐 OTP
      final otp = _generateOtp();

      // 💾 SAVE USER
      await users.add({
        'first_name': first,
        'last_name': last,
        'full_name': '$first $last',
        'username': username,
        'email': email,
        'password': pass, // ⚠️ activity only
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 📧 SEND OTP
      await _sendOtpToEmail(email, otp);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created. OTP sent to Gmail."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      setState(() {
        emailError = "Failed to send OTP. Check Gmail App Password.";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------- UI ----------
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

                buildField("First Name", firstNameController,
                    error: firstNameError),
                const SizedBox(height: 12),

                buildField("Last Name", lastNameController,
                    error: lastNameError),
                const SizedBox(height: 12),

                buildField("Username", usernameController,
                    error: usernameError),
                const SizedBox(height: 12),

                buildField("Email", emailController, error: emailError),
                const SizedBox(height: 12),

                buildField("Password", passwordController,
                    obscure: true, error: passwordError),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72BF00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Create Account",
                            style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              error,
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
