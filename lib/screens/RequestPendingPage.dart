import 'package:flutter/material.dart';

class RequestPendingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large Image at the top
              Image.asset(
                'images/pending.png', // Ensure you have this image in your assets folder
                width: size.width,
                height: size.height * 0.38,
              ),
              SizedBox(height: size.height * 0.02),
              // Descriptive Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                child: Column(
                  children: [
                    Text(
                      'Your Verification Request is Pending',
                      style: TextStyle(
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.02),
                    Text(
                      'Thank you for submitting your business verification request. Our team is currently reviewing your information. This process may take some time, so we appreciate your patience. You will be notified once the verification is complete.',
                      style: TextStyle(
                        fontSize: size.width * 0.04,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
