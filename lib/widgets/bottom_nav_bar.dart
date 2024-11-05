import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:settledin_merchant/screens/add_services.dart';
import '../screens/home_page.dart';
import '../screens/my_services.dart';

class BottomNavBar extends StatefulWidget {
  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize the pages list
    _pages = [
      HomePage(),
      MyServices(),
      AddServices(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index; // Change the index to navigate
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _pages[_currentIndex],
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        color: Colors.white,
        backgroundColor: Colors.grey.shade100,
        animationDuration: Duration(milliseconds: 300),
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              Icons.home_outlined,
              color: _currentIndex == 0 ? Colors.red : Colors.black,
            ),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.home_repair_service_outlined,
              color: _currentIndex == 1 ? Colors.red : Colors.black,
            ),
            label: 'My Services',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              Icons.add,
              color: _currentIndex == 2 ? Colors.red : Colors.black,
            ),
            label: 'Add Services',
          ),
        ],
        buttonBackgroundColor: Colors.white,
        onTap: _onItemTapped,
        height: 75,
      ),
    );
  }
}
