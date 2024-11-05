import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String image;
  final String text;

  OnboardingPage({required this.image, required this.text});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate dynamic values
    double bottomPosition = screenHeight * 0.15; // 15% from the bottom
    double fontSize = screenWidth * 0.04; // Font size based on screen width

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.asset(
          image,
          fit: BoxFit.cover,
        ),
        // Overlay with text
        Positioned(
          bottom: bottomPosition,
          left: 20,
          right: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
