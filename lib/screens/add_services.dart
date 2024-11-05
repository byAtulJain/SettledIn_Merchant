import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:settledin_merchant/screens/profile_page.dart';

class AddServices extends StatefulWidget {
  @override
  _AddServicesState createState() => _AddServicesState();
}

//for user profile
Route _createRouteForProfile() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeAnimation = animation.drive(tween);

      return FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );
    },
    transitionDuration: Duration(milliseconds: 300), // Same duration
  );
}

class _AddServicesState extends State<AddServices> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  LatLng? _selectedLocation;
  String _selectedCategory = 'Hostels'; // Default category

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Predefined categories
  final List<String> _categories = [
    'Hostels',
    'Flats',
    'Tiffins',
    'Laundries',
    'PGs',
    'Libraries',
    'Tuitions',
    'Cooks',
  ];

  // Description hints for each category
  final Map<String, String> _descriptionHints = {
    'Hostels':
        'Mention all the details about services and amenities provided by your hostel like daily cleaning facilities, Good home like food , 24/7 Wi-fi services,Monthly Rent, etc.',
    'Flats':
        'Mention all the details about services and amenities provided in your flat like 1-BHK/2-BHK, fully furnished/partially furnished, Monthly Rent, services, etc.',
    'Tiffins':
        'Mention all the details like tiffin timings, 2 time meal/ 3 time meal, sunday availability, location availability, terms & condition, 2-time & 1-time charges, etc.',
    'Laundries':
        'Mention all details about monthly charges, occasional charges, and many more.',
    'PGs': 'Mention all details about services, rental charge,etc',
    'Libraries':
        'Mention all details about Monthly,weekly,daily charges of library according to hours, services, Wifi facilities and many more provided by you in your library.',
    'Tutions':
        'Mention details about courses , Charges, Faculties, facilities , services, Monthly/ Weekly test, Enquiry & availability hours, etc.',
    'Cooks':
        'Mention details about timings, Gender, and some general information about cook to ensure security and their charges, Veg-NonVeg cooking options and all.',
  };

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(String serviceId) async {
    List<String> imageUrls = [];
    for (File image in _selectedImages) {
      String fileName =
          '${serviceId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref =
          FirebaseStorage.instance.ref().child('services/$fileName');
      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      } else {
        // Show message if no image is captured
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image captured')),
        );
      }
    } catch (e) {
      // Handle any errors that occur
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  // Select time
  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  // Format TimeOfDay to 12-hour format
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  // Get location from address
  Future<void> _getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      print('Error occurred while getting location: $e');
    }
  }

  // Upload service data to Firestore
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedImages.isNotEmpty) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not logged in')),
          );
          return;
        }

        // Batch write to ensure atomic operation
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Create document reference
        DocumentReference serviceRef =
            FirebaseFirestore.instance.collection('services').doc();

        // Upload images first
        _uploadedImageUrls = await _uploadImages(serviceRef.id);

        // Prepare service data
        final serviceData = {
          'name': _nameController.text,
          'price': int.parse(_priceController.text),
          'tags': _selectedCategory,
          'description': _descriptionController.text,
          'address': _addressController.text,
          'openingTime': _formatTime(_openingTime!),
          'closingTime': _formatTime(_closingTime!),
          'location': GeoPoint(
            _selectedLocation?.latitude ?? 0,
            _selectedLocation?.longitude ?? 0,
          ),
          'phoneNumber': _phoneController.text,
          'whatsappNumber': '+91${_whatsappController.text}',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'images': _uploadedImageUrls,
        };

        // Add to batch
        batch.set(serviceRef, serviceData);

        // Commit the batch
        await batch.commit();

        // Close loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service added successfully!')),
        );

        // Clear form
        _clearForm();
      } catch (e) {
        // Close loading indicator
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding service: $e')),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedImages.clear();
      _uploadedImageUrls.clear();
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _addressController.clear();
      _phoneController.clear();
      _whatsappController.clear();
      _openingTime = null;
      _closingTime = null;
      _selectedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.grey.shade100,
        automaticallyImplyLeading: false,
        title: Row(
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Colors.black,
              size: 32,
            ),
            onPressed: () {
              Navigator.of(context).push(_createRouteForProfile());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Selection Section
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _pickImages, // Existing gallery picker
                              icon: Icon(Icons.add_photo_alternate),
                              label: Text('Add Images from Gallery'),
                            ),
                            TextButton.icon(
                              onPressed: _pickImageFromCamera, // Camera picker
                              icon: Icon(Icons.camera_alt),
                              label: Text('Take Photo'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length +
                            2, // Add two options: camera and gallery
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            // Camera button
                            return Center(
                              child: IconButton(
                                onPressed:
                                    _pickImageFromCamera, // Camera picker button
                                icon: Icon(Icons.camera_alt, size: 40),
                              ),
                            );
                          } else if (index == _selectedImages.length + 1) {
                            // Gallery button
                            return Center(
                              child: IconButton(
                                onPressed: _pickImages, // Gallery picker button
                                icon: Icon(Icons.add_photo_alternate, size: 40),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Image.file(
                                  _selectedImages[index],
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
                                      _selectedImages.removeAt(index);
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

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              SizedBox(height: 20),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per month',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a price' : null,
              ),
              SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      _descriptionHints[_selectedCategory] ?? 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a description'
                    : null,
              ),
              SizedBox(height: 20),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address with city name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _getLocationFromAddress(value);
                  }
                },
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter an address' : null,
              ),
              SizedBox(height: 20),

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: Icon(Icons.access_time),
                      label: Text(_openingTime == null
                          ? 'Select Opening Time'
                          : _formatTime(_openingTime!)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context, false),
                      icon: Icon(Icons.access_time),
                      label: Text(_closingTime == null
                          ? 'Select Closing Time'
                          : _formatTime(_closingTime!)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      10), // Limit input to 10 digits
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a phone number'
                    : null,
              ),
              SizedBox(height: 20),

// WhatsApp Number Field
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                      10), // Limit input to 10 digits
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a WhatsApp number'
                    : null,
              ),
              SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Add Service',
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
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }
}
