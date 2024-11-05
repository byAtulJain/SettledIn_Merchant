import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_login_screen.dart'; // Import the Google login screen

class ProfilePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.grey.shade100,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text(
              "Settled",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.black,
              ),
            ),
            Text(
              "In",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Center(
          child: user != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Profile image
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                          user!.photoURL ?? 'https://via.placeholder.com/150'),
                    ),
                    SizedBox(height: 20),
                    // Display name
                    Text(
                      user!.displayName ?? 'No Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Verified tag
                    if (user!.emailVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(height: 10),
                    // Email
                    Text(
                      user!.email ?? 'No Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Logout button
                    ElevatedButton(
                      onPressed: () async {
                        // Clear SharedPreferences
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear(); // Clear all cached data

                        // Sign out from Firebase
                        await FirebaseAuth.instance.signOut();

                        // Navigate to the Google login screen and clear the back stack
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GoogleLoginScreen()),
                          (Route<dynamic> route) =>
                              false, // Removes all previous routes
                        );
                      },
                      child: Text(
                        'LOGOUT',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red, // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                )
              : Text(
                  'No user is signed in.',
                  style: TextStyle(fontSize: 24),
                ),
        ),
      ),
    );
  }
}
