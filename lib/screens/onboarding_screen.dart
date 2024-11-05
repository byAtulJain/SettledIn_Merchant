import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/onboarding_page.dart';
import 'google_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GoogleLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height
    double screenHeight = MediaQuery.of(context).size.height;

    // Position dots at 10% from the bottom
    double dotsPosition = screenHeight * 0.1;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              OnboardingPage(
                image: 'images/on board screen 1.png',
                text:
                    "Set up your profile with a few clicks and attract students with descriptions and photos.",
              ),
              OnboardingPage(
                image: 'images/on board screen 2.png',
                text:
                    "Get discovered by students and newcomers looking for reliable services in the city.",
              ),
              OnboardingPage(
                image: 'images/on board screen 3.png',
                text:
                    " Let students book or order directly through the app for a seamless experience.",
              ),
            ],
          ),
          // Sliding dots indicator
          Positioned(
            bottom: dotsPosition,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => buildDot(index, context)),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            child: _currentIndex != 2
                ? TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : SizedBox(),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: _currentIndex == 2
                ? TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentIndex == index ? 20 : 10,
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: _currentIndex == index ? Colors.blue : Colors.grey,
      ),
    );
  }
}
