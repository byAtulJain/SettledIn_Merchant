import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'RequestPendingPage.dart';

class BusinessVerificationScreen extends StatefulWidget {
  final User user; // Add this line to accept a User object

  BusinessVerificationScreen(
      {required this.user}); // Add constructor to accept User

  @override
  _BusinessVerificationScreenState createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends State<BusinessVerificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final picker = ImagePicker();
  List<File> _businessImages = [];
  String? _businessName, _realName, _gender, _phone, _aboutBusiness;
  int? _age;
  bool _isSubmitting = false;

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _businessImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _businessImages.add(File(image.path));
      });
    }
  }

  // Upload business images to Firebase Storage
  Future<List<String>> _uploadBusinessImages() async {
    List<String> imageUrls = [];
    for (File image in _businessImages) {
      String fileName = basename(image.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('merchant_business_verification')
          .child(fileName);
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<void> _submitVerificationForm(BuildContext context) async {
    if (_businessImages.isEmpty ||
        _businessName == null ||
        _realName == null ||
        _age == null ||
        _gender == null ||
        _phone == null ||
        _aboutBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Please fill all fields and upload your business card!')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> imageUrls = await _uploadBusinessImages();
      User user = widget.user; // Use the passed-in user here

      // Update Firestore with user verification data
      await _firestore.collection('merchants').doc(user.uid).update({
        'businessName': _businessName,
        'realName': _realName,
        'age': _age,
        'gender': _gender,
        'phone': _phone,
        'aboutBusiness': _aboutBusiness,
        'businessCardUrls': imageUrls,
        'verificationStatus': 'pending',
      });

      // Save login credentials and verification state in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true); // Set login state
      await prefs.setBool('isVerified', true); // Set verification state

      // Clear all fields
      setState(() {
        _businessImages.clear();
        _businessName = null;
        _realName = null;
        _age = null;
        _gender = null;
        _phone = null;
        _aboutBusiness = null;
      });

      // Navigate to the RequestPendingPage to show pending status
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RequestPendingPage()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Business Verification')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Selection Section
            // Image Selection Section
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _businessImages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Upload your business card/poster',
                            style: TextStyle(
                              color: Colors.grey, // Text color for guidance
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                              height:
                                  10), // Add some space between the text and buttons
                          TextButton.icon(
                            onPressed: _pickImages,
                            icon: Icon(Icons.add_photo_alternate),
                            label: Text('Add Images from Gallery'),
                          ),
                          TextButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Take Photo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _businessImages.length + 2,
                      itemBuilder: (context, index) {
                        if (index == _businessImages.length) {
                          return Center(
                            child: IconButton(
                              onPressed: _pickImageFromCamera,
                              icon: Icon(Icons.camera_alt, size: 40),
                            ),
                          );
                        } else if (index == _businessImages.length + 1) {
                          return Center(
                            child: IconButton(
                              onPressed: _pickImages,
                              icon: Icon(Icons.add_photo_alternate, size: 40),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Image.file(
                                _businessImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _businessImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _businessName = value,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Real Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _realName = value,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _age = int.tryParse(value),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: ['Male', 'Female', 'Other'].map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _phone = value,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'About Business',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
              onChanged: (value) => _aboutBusiness = value,
            ),
            SizedBox(height: 20),
            _isSubmitting
                ? CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _submitVerificationForm(context); // Pass context here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
