import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:settledin_merchant/screens/profile_page.dart';
import 'detail_service_page.dart';
import 'edit_service_page.dart'; // Import the edit service page

class MyServices extends StatefulWidget {
  @override
  _MyServicesState createState() => _MyServicesState();
}

class _MyServicesState extends State<MyServices> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String searchQuery = '';
  String _sortOrder = 'recently_added';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  Stream<List<Map<String, dynamic>>> fetchUserServices() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = FirebaseFirestore.instance
        .collection('services')
        .where('userId', isEqualTo: user.uid);

    return query.snapshots().map((snapshot) {
      List<Map<String, dynamic>> services = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'images': List<String>.from(doc['images']), // Fetch multiple images
          'name': doc['name'],
          'price': doc['price'], // Fetch price as int
          'tags': doc['tags'],
          'description': doc['description'],
          'address': doc['address'],
          'openingTime': doc['openingTime'],
          'closingTime': doc['closingTime'],
          'location': doc['location'],
          'phoneNumber': doc['phoneNumber'],
          'whatsappNumber': doc['whatsappNumber'],
          'timestamp': doc['timestamp'],
        };
      }).where((service) {
        final query = searchQuery.toLowerCase();
        return service['name'].toLowerCase().contains(query) ||
            service['price'].toString().contains(query) ||
            service['description'].toLowerCase().contains(query) ||
            service['address'].toLowerCase().contains(query) ||
            service['tags'].toLowerCase().contains(query);
      }).toList();

      if (_sortOrder == 'low_to_high') {
        services.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (_sortOrder == 'high_to_low') {
        services.sort((a, b) => b['price'].compareTo(a['price']));
      } else if (_sortOrder == 'recently_added') {
        services.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      }

      return services;
    });
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Recently Added'),
                onTap: () {
                  setState(() {
                    _sortOrder = 'recently_added';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Low to High'),
                onTap: () {
                  setState(() {
                    _sortOrder = 'low_to_high';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('High to Low'),
                onTap: () {
                  setState(() {
                    _sortOrder = 'high_to_low';
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceBox({
    required List<String> images,
    required String name,
    required int price,
    required String address,
    required String tags,
    required String serviceId, // Add serviceId to the parameters
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(images[0]), // Display the first image
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  'Rs. $price${tags.toLowerCase() == 'laundries' ? '/load' : '/month'}',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.grey),
            onPressed: () {
              Navigator.of(context).push(_createRouteForEdit(serviceId));
            },
          ),
        ],
      ),
    );
  }

  Route _createRouteForProfile() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 300), // Same duration
    );
  }

  Route _createRouteForDetail(Map<String, dynamic> service) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          DetailServicePage(
        images: service['images'],
        name: service['name'],
        price: service['price'],
        tags: service['tags'],
        description: service['description'],
        address: service['address'],
        openingTime: service['openingTime'],
        closingTime: service['closingTime'],
        location: LatLng(
          service['location'].latitude,
          service['location'].longitude,
        ),
        phoneNumber: service['phoneNumber'],
        whatsappNumber: service['whatsappNumber'],
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 300), // Same duration
    );
  }

  Route _createRouteForEdit(String serviceId) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          EditServicePage(serviceId: serviceId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: 300), // Same duration
    );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar with filter icon
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Find your needs',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.grey),
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Services List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchUserServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No services found.'));
                }
                return Column(
                  children: snapshot.data!.map((service) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(_createRouteForDetail(service));
                      },
                      child: _buildServiceBox(
                        images: service['images'],
                        name: service['name'],
                        price: service['price'],
                        address: service['address'],
                        tags: service['tags'],
                        serviceId: service['id'], // Pass the serviceId
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
