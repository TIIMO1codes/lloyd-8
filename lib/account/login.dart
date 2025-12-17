import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart';
import '../navigation/home_page.dart';
import '../otp_page.dart';
import '../login_notifier.dart'; // ✅ ADD THIS

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  String errorMessage = "";
  bool isSigningIn = false;

  // ---------------- NORMAL LOGIN ----------------

  Future<void> login() async {
    final username = usernameController.text.trim();
    final pass = passwordController.text.trim();
    final otp = otpController.text.trim();

    if (username.isEmpty || pass.isEmpty || otp.isEmpty) {
      setState(() => errorMessage = "Please fill all fields.");
      return;
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .where("password", isEqualTo: pass)
          .get();

      if (result.docs.isEmpty) {
        setState(() => errorMessage = "Invalid username or password.");
        return;
      }

      final userDoc = result.docs.first;
      final storedOtp = userDoc.data()['otp'];

      if (storedOtp == null || storedOtp != otp) {
        setState(() => errorMessage = "Invalid OTP.");
        return;
      }

      // ✅ SEND LOGIN ALERT EMAIL
      final email = userDoc.data()['email'];
      if (email != null) {
        await LoginNotifier.sendLoginAlert(email);
      }

      // ✅ LOGIN SUCCESS
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() => errorMessage = "Login failed.");
    }
  }

  /// ---------------- GOOGLE → OTP → HOME ----------------

  Future<void> loginWithGoogle() async {
    if (isSigningIn) return;
    setState(() => isSigningIn = true);

    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isSigningIn = false);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: googleUser.email,
            onVerified: () async {
              final googleAuth = await googleUser.authentication;

              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );

              final userCredential = await FirebaseAuth.instance
                  .signInWithCredential(credential);

              final user = userCredential.user!;
              final uid = user.uid;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .set({
                'uid': uid,
                'email': user.email,
                'name': user.displayName ?? 'Google User',
                'photoUrl': user.photoURL,
                'provider': 'google',
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              // ✅ SEND LOGIN ALERT EMAIL
              if (user.email != null) {
                await LoginNotifier.sendLoginAlert(user.email!);
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => errorMessage = "Google Sign-In failed");
    } finally {
      setState(() => isSigningIn = false);
    }
  }

  // ---------------- UI ----------------

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
                  "Welcome Back",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Username"),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Password"),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("OTP"),
                ),
                const SizedBox(height: 10),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF72BF00),
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Color(0xFF72BF00)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isSigningIn ? null : loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isSigningIn
                          ? "Signing in..."
                          : "Continue with Google",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
