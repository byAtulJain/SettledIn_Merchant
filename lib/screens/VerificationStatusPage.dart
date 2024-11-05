import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import 'DisapprovedPage.dart';
import 'RequestPendingPage.dart';

class VerificationStatusPage extends StatefulWidget {
  @override
  _VerificationStatusPageState createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('merchants').doc(user.uid).get();
      String status = doc['verificationStatus'];

      if (status == 'approved') {
        // If verified, navigate to main app (BottomNavBar)
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BottomNavBar()));
      } else if (status == 'disapproved') {
        // If verification is disapproved, show the disapproved page
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => DisapprovedPage()));
      } else {
        // If verification is pending, show the request pending page
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => RequestPendingPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
