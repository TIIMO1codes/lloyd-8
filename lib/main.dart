import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigation/home_page.dart';
import 'account/login.dart';
import 'account/signup.dart';
import 'navigation/lyrics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDI2saNXmFKRYvAVVMbaeHys3Q2p2iw_Iw",
      appId: "1:69127242012:android:2f3199fe75921058a6bad9",
      messagingSenderId: "69127242012",
      projectId: "loginlloyd-1d7c7",
      storageBucket: "loginlloyd-1d7c7.firebasestorage.app",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Song Lyrics Display',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        scaffoldBackgroundColor: Colors.black87,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/lyrics') {
          final args = settings.arguments as Map?;
          if (args == null ||
              !args.containsKey('songs') ||
              !args.containsKey('index')) {
            return _errorRoute();
          }
          return MaterialPageRoute(
            builder: (context) =>
                LyricsPage(songs: args['songs'], startIndex: args['index']),
          );
        }
        return null;
      },
    );
  }

  MaterialPageRoute _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text(
            'Failed to load song data.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
