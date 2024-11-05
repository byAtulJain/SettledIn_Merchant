import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:settledin_merchant/screens/VerificationStatusPage.dart';
import 'package:settledin_merchant/screens/google_login_screen.dart';
import 'package:settledin_merchant/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SettledIn',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: CheckFirstTime(),
    );
  }
}

class CheckFirstTime extends StatefulWidget {
  @override
  _CheckFirstTimeState createState() => _CheckFirstTimeState();
}

class _CheckFirstTimeState extends State<CheckFirstTime> {
  @override
  void initState() {
    super.initState();
    _navigateToSplash();
  }

  _navigateToSplash() async {
    // Show splash screen for 3 seconds
    await Future.delayed(Duration(seconds: 3), () {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('isFirstTime');
    bool? isLoggedIn = prefs.getBool('isLoggedIn'); // Login state
    bool? isVerified = prefs.getBool('isVerified'); // Verification state

    if (isLoggedIn == true && isVerified == true) {
      // User is logged in and verified, navigate to VerificationStatusPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerificationStatusPage()),
      );
    } else if (isFirstTime == null || isFirstTime) {
      // First time, show onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    } else {
      // Not first time, show Google login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GoogleLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(); // Always show splash screen first
  }
}
