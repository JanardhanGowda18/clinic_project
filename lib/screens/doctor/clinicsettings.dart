import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClinicSettings extends StatelessWidget {
  final ClinicSettingsData clinicData;

  ClinicSettings({required this.clinicData});

  Future<void> _changePassword(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password Reset Email Sent. Check your inbox.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        _showErrorDialog(context, 'User not authenticated.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'clinikx',
          style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Container(
            width: 400,
            height: 400,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 110,bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center, // Center the details vertically
                  children: [
                    _buildInfoItem('Clinic Name', clinicData.clinicName),
                    _buildInfoItem('Address', clinicData.address),
                    _buildInfoItem('Phone Number', clinicData.phoneNumber),
                    _buildInfoItem('Working Hours', clinicData.workingHours),

                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(right: 100,left: 0),
                      child: ElevatedButton(
                        onPressed: () => _changePassword(context),
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Text('Change Password'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ClinicSettingsData {
  final String clinicName;
  final String address;
  final String phoneNumber;
  final String workingHours;

  ClinicSettingsData({
    required this.clinicName,
    required this.address,
    required this.phoneNumber,
    required this.workingHours,
  });
}