import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class EditServicePage extends StatefulWidget {
  final String serviceId;

  EditServicePage({required this.serviceId});

  @override
  _EditServicePageState createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
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

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  Future<void> _loadServiceData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceId)
        .get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'];
        _priceController.text = data['price'].toString();
        _descriptionController.text = data['description'];
        _addressController.text = data['address'];
        _phoneController.text = data['phoneNumber'];
        _whatsappController.text =
            data['whatsappNumber'].replaceFirst('+91', '');
        _selectedCategory = data['tags'];
        _openingTime = _parseTime(data['openingTime']);
        _closingTime = _parseTime(data['closingTime']);
        _selectedLocation = LatLng(
          data['location'].latitude,
          data['location'].longitude,
        );
        _uploadedImageUrls = List<String>.from(data['images']);
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final format = DateFormat.jm();
    final dateTime = format.parse(time);
    return TimeOfDay.fromDateTime(dateTime);
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

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

  Future<void> _uploadImages(String serviceId) async {
    for (File image in _selectedImages) {
      String fileName =
          '${serviceId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref =
          FirebaseStorage.instance.ref().child('services/$fileName');
      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();
      _uploadedImageUrls.add(downloadUrl);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        await _uploadImages(widget.serviceId);

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
          'images': _uploadedImageUrls,
        };

        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.serviceId)
            .update(serviceData);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service updated successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating service: $e')),
        );
      }
    }
  }

  Future<void> _deleteService() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Step 1: Retrieve the service document to get the image URLs
      DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceDoc.exists) {
        List<dynamic> imageUrls =
            serviceDoc['images']; // Retrieve the image URLs

        // Step 2: Delete each image from Firebase Storage
        for (var imageUrl in imageUrls) {
          try {
            Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await imageRef.delete();
          } catch (e) {
            // Handle any error in deleting individual images, but continue deleting others
            print('Error deleting image: $e');
          }
        }

        // Step 3: Delete the service from Firestore
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.serviceId)
            .delete();

        Navigator.of(context).pop(); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Service and its images deleted successfully!')),
        );

        Navigator.of(context).pop(); // Return to the previous screen
      } else {
        // If the document doesn't exist, close the loading dialog and show an error
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service not found!')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service: $e')),
      );
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    try {
      // Remove image from Firebase Storage
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      // Remove image URL from the list
      setState(() {
        _uploadedImageUrls.remove(imageUrl);
      });

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({'images': _uploadedImageUrls});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image removed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing image: $e')),
      );
    }
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
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteService,
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
                child: _uploadedImageUrls.isEmpty && _selectedImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                        itemCount: _uploadedImageUrls.length +
                            _selectedImages.length +
                            2,
                        itemBuilder: (context, index) {
                          if (index < _uploadedImageUrls.length) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Image.network(
                                    _uploadedImageUrls[index],
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
                                      _removeImage(_uploadedImageUrls[index]);
                                    },
                                  ),
                                ),
                              ],
                            );
                          } else if (index <
                              _uploadedImageUrls.length +
                                  _selectedImages.length) {
                            int localIndex = index - _uploadedImageUrls.length;
                            return Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Image.file(
                                    _selectedImages[localIndex],
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
                                        _selectedImages.removeAt(localIndex);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          } else if (index ==
                              _uploadedImageUrls.length +
                                  _selectedImages.length) {
                            return Center(
                              child: IconButton(
                                onPressed: _pickImageFromCamera,
                                icon: Icon(Icons.camera_alt, size: 40),
                              ),
                            );
                          } else {
                            return Center(
                              child: IconButton(
                                onPressed: _pickImages,
                                icon: Icon(Icons.add_photo_alternate, size: 40),
                              ),
                            );
                          }
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
                  labelText: 'Price',
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
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
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
                  labelText: 'Address',
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
                    'Update Service',
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
