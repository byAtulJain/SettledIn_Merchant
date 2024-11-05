import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For WhatsApp icon
import 'package:url_launcher/url_launcher.dart'; // To handle URL launching
import 'package:whatsapp_unilink/whatsapp_unilink.dart'; // For WhatsApp links
import 'package:carousel_slider/carousel_slider.dart'; // Add this import

class DetailServicePage extends StatefulWidget {
  final List<String> images;
  final String name;
  final int price; // Change price to int
  final String tags;
  final String description;
  final String address;
  final String openingTime;
  final String closingTime;
  final LatLng location;
  final String phoneNumber;
  final String whatsappNumber;

  DetailServicePage({
    required this.images,
    required this.name,
    required this.price,
    required this.tags,
    required this.description,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    required this.location,
    required this.phoneNumber,
    required this.whatsappNumber,
  });

  @override
  State<DetailServicePage> createState() => _DetailServicePageState();
}

class _DetailServicePageState extends State<DetailServicePage> {
  // Function to open phone dialer
  void _launchPhoneDialer(String phoneNumber) async {
    bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res == null || !res) {
      print('Could not place the call.');
    }
  }

  // Function to open WhatsApp chat
  void _launchWhatsApp(String whatsappNumber) async {
    final link = WhatsAppUnilink(
      phoneNumber: whatsappNumber,
      text: "Hello, I'm interested in your services.", // Predefined message
    );
    await launchUrl(Uri.parse('$link'));
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display images in a carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 250,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  autoPlay: true,
                ),
                items: widget.images.map((image) {
                  return Container(
                    margin: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Display name
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // Display price
              Text(
                "Rs. ${widget.price}${widget.tags.toLowerCase() == 'laundries' ? '/load' : '/month'}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              // Display tags
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red, // Same red color as categories
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.tags, // Directly using the string
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Text in white
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Display description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              // Display address
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                widget.address,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              // Display timing
              Text(
                'Timing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Opening Time: ${widget.openingTime}',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                'Closing Time: ${widget.closingTime}',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              // Display Google Map location
              Container(
                height: 200,
                decoration: BoxDecoration(
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
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.location,
                    zoom: 14.0,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('serviceLocation'),
                      position: widget.location,
                    ),
                  },
                ),
              ),
              SizedBox(height: 20),
              // Phone and WhatsApp buttons at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Contact Us Button
                  ElevatedButton.icon(
                    onPressed: () {
                      _launchPhoneDialer(
                          widget.phoneNumber); // Trigger phone dialer
                    },
                    icon: Icon(
                      Icons.phone, // Phone icon
                      color: Colors.white, // White phone icon
                    ),
                    label: Text(
                      'Contact Us',
                      style: TextStyle(
                        color: Colors.white, // White text
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      backgroundColor: Colors.red, // Red background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  // WhatsApp Button
                  ElevatedButton.icon(
                    onPressed: () {
                      _launchWhatsApp(
                          widget.whatsappNumber); // Trigger WhatsApp chat
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white, // White WhatsApp icon
                    ),
                    label: Text(
                      'WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      backgroundColor:
                          Colors.green, // Green WhatsApp background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
