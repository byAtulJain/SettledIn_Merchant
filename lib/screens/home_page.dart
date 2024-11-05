import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:settledin_merchant/screens/profile_page.dart';
import 'detail_service_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

// For user profile
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

// For detail service page
Route _createRouteForDetail(Map<String, dynamic> service) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => DetailServicePage(
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

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String searchQuery = '';
  String _sortOrder = 'recently_added';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  final List<String> categories = [
    'All',
    'Hostels',
    'Flats',
    'Tiffins',
    'Laundries',
    'PGs',
    'Libraries',
    'Tuitions',
    'Cooks',
  ];

  List<Map<String, dynamic>>? _cachedServices;

  Stream<List<Map<String, dynamic>>> fetchServices() {
    Query query = FirebaseFirestore.instance.collection('services');

    if (selectedIndex != 0) {
      String selectedCategory = categories[selectedIndex];
      query = query.where('tags', isEqualTo: selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      List<Map<String, dynamic>> services = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'images': List<String>.from(doc['images']),
          'name': doc['name'],
          'price': doc['price'],
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

      // Update cache
      _cachedServices = services;
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
        ],
      ),
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
            Container(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(right: 10),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            selectedIndex == index ? Colors.red : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Services List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: fetchServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedServices == null) {
                  return Center(child: CircularProgressIndicator());
                }

                // Use cached data if available
                final services = snapshot.data ?? _cachedServices;

                if (services == null || services.isEmpty) {
                  return Center(child: Text('No services found.'));
                }

                return Column(
                  children: services.map((service) {
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
