import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogUtils {
  static void showDetailsDialog(
      BuildContext context, Map<String, dynamic> data, String Function(Map<String, dynamic>) formatter) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Patient Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient ID: ${data['pid']?.toString() ?? 'Unknown'}'),
              Text('Name: ${data['name'] ?? 'Unknown'}'),
              Text('Age: ${data['age']?.toString() ?? 'Unknown'}'),
              Text('Disease: ${data['disease'] ?? 'Unknown'}'),
              Text('Gender: ${data['gender'] ?? 'Unknown'}'),
              Text('Phone Number: ${data['phoneNumber'] ?? 'Unknown'}'),
              Text('Time and Date: ${formatter(data)}'),
              // Add more details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}



  String formattedTimestamp(Map<String, dynamic> patientData) {
    Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
    DateTime? dateTime = timestamp?.toDate();
    return dateTime != null
        ? DateFormat.yMd().add_Hm().format(dateTime)
        : 'N/A';
  }
