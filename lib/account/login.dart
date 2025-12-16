import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup.dart';
import '../navigation/home_page.dart';
import '../otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = "";
  bool isSigningIn = false;

  Future<void> login() async {
    final username = usernameController.text.trim();
    final pass = passwordController.text.trim();

    if (username.isEmpty || pass.isEmpty) {
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } catch (e) {
      setState(() => errorMessage = "Login failed");
    }
  }

  /// ✅ GOOGLE → OTP → HOME
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
            // 🔥 ONLY AFTER OTP
            final googleAuth = await googleUser.authentication;

            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );

            final userCredential = await FirebaseAuth.instance
                .signInWithCredential(credential);

            final user = userCredential.user!;
            final uid = user.uid;

            // ✅ SAVE TO FIRESTORE HERE (AFTER OTP)
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
                  decoration: InputDecoration(
                    labelText: "Username",
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
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
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
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          const Color(0xFF72BF00),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style:
                          TextStyle(color: Color(0xFF72BF00)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        isSigningIn ? null : loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.white70),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                    child: Text(
                      isSigningIn
                          ? "Signing in..."
                          : "Continue with Google",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16),
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
