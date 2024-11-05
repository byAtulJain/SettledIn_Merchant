import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:settledin_merchant/firebase_options.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate sizes and positions based on screen dimensions
    double imageSize = screenWidth * 0.5; // Image takes up 50% of screen width
    double spacing = screenHeight * 0.1; // Spacing is 10% of screen height
    double spinnerSize =
        screenWidth * 0.1; // Spinner size is 10% of screen width

    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Responsive image without box decoration or shadow
                  Image.asset(
                    'images/splash_screen.png',
                    width: imageSize,
                    height: imageSize, // Adjust as needed
                  ),
                  SizedBox(height: spacing),
                  // Responsive spinner size
                  SpinKitWave(
                    color: Color(0xFFff0000),
                    size: spinnerSize,
                  ),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
