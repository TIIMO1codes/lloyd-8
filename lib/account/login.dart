import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'signup.dart';
import '../navigation/home_page.dart';
import '../otp_page.dart';
import '../login_notifier.dart';

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
  bool isLoggingIn = false;

  // ================= NORMAL LOGIN =================

  Future<void> login() async {
    if (isLoggingIn) return;

    setState(() {
      errorMessage = "";
      isLoggingIn = true;
    });

    final username = usernameController.text.trim();
    final pass = passwordController.text.trim();
    final otp = otpController.text.trim();

    if (username.isEmpty || pass.isEmpty || otp.isEmpty) {
      setState(() {
        errorMessage = "Please fill all fields.";
        isLoggingIn = false;
      });
      return;
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .where("password", isEqualTo: pass)
          .get();

      if (result.docs.isEmpty) {
        setState(() {
          errorMessage = "Invalid username or password.";
          isLoggingIn = false;
        });
        return;
      }

      final userDoc = result.docs.first.data();

      if (userDoc['otp'] != otp) {
        setState(() {
          errorMessage = "Invalid OTP.";
          isLoggingIn = false;
        });
        return;
      }

      final firstName = userDoc['first_name'] ?? '';
      final lastName = userDoc['last_name'] ?? '';
      final email = userDoc['email'] ?? '';
      final fullName = '$firstName $lastName'.trim();

      if (email.isNotEmpty) {
        await LoginNotifier.sendLoginAlert(email);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: RouteSettings(
            arguments: {
              'type': 'normal',
              'name': fullName,
              'email': email,
            },
          ),
        ),
      );
    } catch (_) {
      setState(() => errorMessage = "Login failed.");
    } finally {
      setState(() => isLoggingIn = false);
    }
  }

  // ================= GOOGLE LOGIN =================

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

              final parts = (user.displayName ?? '').split(' ');
              final firstName = parts.isNotEmpty ? parts.first : '';
              final lastName =
                  parts.length > 1 ? parts.sublist(1).join(' ') : '';

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .set({
                'uid': uid,
                'email': user.email,
                'first_name': firstName,
                'last_name': lastName,
                'photoUrl': user.photoURL,
                'provider': 'google',
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

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
    } catch (_) {
      setState(() => errorMessage = "Google Sign-In failed.");
    } finally {
      setState(() => isSigningIn = false);
    }
  }

  // ================= UI =================

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

                _input(usernameController, "Username"),
                const SizedBox(height: 15),
                _input(passwordController, "Password", obscure: true),
                const SizedBox(height: 15),
                _input(otpController, "OTP", number: true),

                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(errorMessage,
                      style: const TextStyle(color: Colors.redAccent)),
                ],

                const SizedBox(height: 25),

                // ================= LOADING BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoggingIn ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72BF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoggingIn
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 32,
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
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
                    child: isSigningIn
                        ? LoadingAnimationWidget.horizontalRotatingDots(
                            color: Colors.white,
                            size: 24,
                          )
                        : const Text(
                            "Continue with Google",
                            style: TextStyle(
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

  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: number ? TextInputType.number : TextInputType.text,
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
