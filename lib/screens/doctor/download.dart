// import 'package:csv/csv.dart';
// import 'dart:io';
//
// void _downloadDetails(Map<String, dynamic> patientData) async {
//   List<List<dynamic>> rows = [];
//
//   // Add header row
//   rows.add(['Field', 'Value']);
//
//   // Add patient details
//   patientData.forEach((key, value) {
//     rows.add([key, value ?? 'Unknown']);
//   });
//
//   String csvData = const ListToCsvConverter().convert(rows);
//
//   // Get the directory for storing files
//   Directory directory = await getApplicationDocumentsDirectory();
//   String filePath = '${directory.path}/patient_details.csv';
//
//   // Write to the file
//   File file = File(filePath);
//   await file.writeAsString(csvData);
//
//   // Show a confirmation message
//   print('Patient details downloaded to: $filePath');
// }
