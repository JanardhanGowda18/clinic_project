import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'TodaysAppointment.dart';
import 'admin.dart';
import 'clinicsettings.dart';
import 'doctor_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double _selectedItemScale = 1.0;
  int _selectedIndex = 0; // Set default to AdminPage
  Color myBlueColor = Colors.cyan[900]!;
  Color clinikxBlue = Color(0xff6495ED );
  Color mixedBluePinkColor = Color.fromRGBO(100, 149, 237, 1.0);
  LinearGradient mixedBluePinkAccentColor = LinearGradient(
    colors: [
      Color(0xFF6495ED), // Cornflower Blue
      Color(0xFFFFB6C1), // Soft Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo image here
            Padding(
              padding: const EdgeInsets.only(right: 8.0,left: 200),
              child: Image.asset(
                'assets/images/cliniclogo.jpeg', // Replace with your logo image path
                width: 200, // Adjust the width as needed
                height: 180, // Adjust the height as needed
              ),
            ),

          ],
        ),
        actions: [
          // Container for the logout button and text with blue border
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10, right: 20, bottom: 5),
            child: Container(
              padding: EdgeInsets.only(top: 2, left: 10, right: 10, bottom: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(Icons.logout),
                    iconSize: 24.0,
                    onPressed: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          child: Container(
            color: Colors.grey,
            height: 3.0,
          ),
          preferredSize: Size.fromHeight(1.0),
        ),
      ),
// ...

      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Row(
            children: [
              Container(
                width: 180,
                color: Colors.white,
                child: Material(
                  // elevation: 4.0,
                  color: Colors.white,
                  clipBehavior: Clip.none,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Column(
                        children: [
                          _buildZoomingNavigationRailDestination(
                          "Today Appointment", "assets/gif/calender.gif", 1),
                          _buildZoomingNavigationRailDestination(
                        "All Appointment", "assets/gif/dashboard.gif", 0),
                          _buildZoomingNavigationRailDestination(
                              "Clinic Settings", "assets/gif/settings.gif", 2),
                          _buildZoomingNavigationRailDestination(
                              "Promotions", "assets/gif/promotion.gif", 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                color: Colors.grey, // Set your desired divider color here
                thickness: 2.0, // Set your desired divider thickness here
              ),
              Expanded(
                child: Card(
                  elevation: 4.0,
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildPage(_selectedIndex),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() async {
    bool? confirmLogout = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
              (route) => false,
        );
      } catch (e) {
        print('Error logging out: $e');
      }
    }
  }

  Widget _buildZoomingNavigationRailDestination(
      String label, String gifPath, int index,
      ) {
    double iconSize = _getIconSize(index);
    double scaleFactor = _getScaleFactor(index);
    double fontSize = _getFontSize(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: 180, // Adjust the width here
        decoration: BoxDecoration(
          gradient: _selectedIndex == index ? mixedBluePinkAccentColor : null,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 40, bottom: 10),
              child: Column(
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                          print('Image tapped!');
                        },
                        child: Transform.scale(
                          scale: scaleFactor,
                          child: CachedNetworkImage(
                            imageUrl: gifPath,
                            width: iconSize,
                            height: iconSize,
                            color: _selectedIndex == index ? Colors.black : Colors.grey,
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            imageBuilder: (context, imageProvider) {
                              return Image(
                                image: imageProvider,
                                width: iconSize,
                                height: iconSize,
                                color: _selectedIndex == index ? Colors.black : Colors.grey,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: _selectedIndex == index ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }









  double _getScaleFactor(int currentIndex) {
    return _selectedIndex == currentIndex ? 1.2 : 1.0;
  }

  double _getIconSize(int currentIndex) {
    return _selectedIndex == currentIndex ? 40.0 : 30.0;
  }

  double _getFontSize(int currentIndex) {
    return _selectedIndex == currentIndex ? 16.0 : 13.0;
  }

  void _logout() async {
    bool? confirmLogout = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
              (route) => false,
        );
      } catch (e) {
        print('Error logging out: $e');
      }
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return AdminPage();
      case 1:
        return TodaysAppointment();
      case 2:
        ClinicSettingsData clinicData = ClinicSettingsData(
          clinicName: 'Indira Clinic',
          address: 'RR NAGAR',
          phoneNumber: ' +91 9876543211',
          workingHours:
          ' Morning : 10:30 AM to 2:00 PM \n Evening :  4:30 PM to 9:30 PM',
        );

        return ClinicSettings(clinicData: clinicData);
      case 3:
        return Promotions();
      case 4:
        _delayedLogout();
        return Container();
      default:
        return Container();
    }
  }

  Future<void> _delayedLogout() async {
    await Future.delayed(Duration.zero);
    _logout();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class Promotions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Promotions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}