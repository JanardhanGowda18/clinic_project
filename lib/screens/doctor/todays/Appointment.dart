// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../../services/firebase_service.dart';
//
// class TodaysAppointmentDataSource extends DataTableSource {
//   // Instance variables
//   final List<Map<String, dynamic>> _data;
//   final BuildContext context;
//   final Future<List<Map<String, dynamic>>> Function() fetchAppointments;
//   final Function(String, int) sendMessage;
//   final Function() incrementTokenCounter;
//   final Function(int, String) savePrescription;
//
//   // Constructor
//   TodaysAppointmentDataSource(
//       this._data,
//       this.context,
//       this.fetchAppointments,
//       this.sendMessage,
//       this.incrementTokenCounter,
//       this.savePrescription,
//       );
//   int tokenCounter = 1;
//
//   @override
//   DataRow getRow(int index) {
//     final appointmentData = _data[index];
//     return DataRow(
//       cells: [
//         DataCell(
//           InkWell(
//             onTap: () {
//               _showDetailsDialog(context, appointmentData);
//             },
//             child: Text(appointmentData['pid']?.toString() ?? 'Unknown'),
//           ),
//         ),
//         DataCell(
//           InkWell(
//             onTap: () {
//               _showDetailsDialog(context, appointmentData);
//             },
//             child: Text(appointmentData['name'] ?? 'Unknown'),
//           ),
//         ),
//         DataCell(Text(appointmentData['disease'] ?? 'Unknown')),
//         DataCell(Text(formattedTimestamp(appointmentData))),
//         DataCell(
//           IconButton(
//             icon: Icon(Icons.edit),
//             onPressed: () {
//               _showPrescriptionModal(context, appointmentData['pid'], index); // Pass index here
//             },
//           ),
//         ),
//         DataCell(
//           Row(
//             children: [
//               IconButton(
//                 icon: Icon(Icons.message),
//                 onPressed: () {
//                   String phoneNumber = appointmentData['phoneNumber'];
//                   if (phoneNumber != null) {
//                     sendMessage(phoneNumber, ++tokenCounter);
//                   } else {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: Text('Phone Number Not Available'),
//                           content: Text(
//                               'The phone number for this appointment is not available.'),
//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).pop();
//                               },
//                               child: Text('OK'),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   }
//                 },
//               ),
//               IconButton(
//                 icon: Image.asset(
//                   'assets/images/whatsapp.png',
//                   width: 24,
//                   height: 24,
//                 ),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//         ),
//         DataCell(
//           IconButton(
//             icon: Icon(Icons.delete),
//             onPressed: () {
//               _deleteAppointment(appointmentData['pid']);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   bool get isRowCountApproximate => false;
//
//   @override
//   int get rowCount => _data.length;
//
//   @override
//   int get selectedRowCount => 0;
//
//   String formattedTimestamp(Map<String, dynamic> patientData) {
//     Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
//     DateTime? dateTime = timestamp?.toDate();
//     return dateTime != null
//         ? DateFormat.yMd().add_Hm().format(dateTime)
//         : 'N/A';
//   }
//
//
//   void _deleteAppointment(int? pid) async {
//     try {
//       bool confirmDelete = await showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Confirm Deletion'),
//             content: Text('Are you sure you want to delete this appointment?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: Text('Delete'),
//               ),
//             ],
//           );
//         },
//       );
//
//       if (confirmDelete == true) {
//         print('Deleting appointment with pid: $pid');
//         // Implement the logic to delete the appointment using FirebaseService
//         await FirebaseService.deleteAppointment(pid);
//         print('Appointment deleted successfully');
//         // After deletion, you might want to refresh the appointment data
//         _fetchPatientData();
//       }
//     } catch (e) {
//       print('Error deleting appointment: $e');
//       // Handle error as needed
//     }
//   }
//
//   void _showPrescriptionModal(BuildContext context, int pid, int index) {
//     String prescription = ''; // State to hold the prescription text
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.5,
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text(
//                   'Write Prescription',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 16.0),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: TextFormField(
//                       initialValue: prescription,
//                       maxLines: null, // Allow the TextFormField to expand vertically
//                       keyboardType: TextInputType.multiline,
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(),
//                         hintText: 'Enter prescription',
//                       ),
//                       onChanged: (value) {
//                         prescription = value;
//                       },
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16.0),
//                 ElevatedButton(
//                   onPressed: () async {
//                     // Save the prescription to the database for the particular patient (pid)
//                     _savePrescription(pid, prescription);
//                     Navigator.pop(context); // Close the modal
//                   },
//                   child: Text('Save Prescription'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showDetailsDialog(BuildContext context, Map<String, dynamic> appointmentData) async {
//     try {
//       // Get the patient ID from the appointment data
//       int? pid = appointmentData['pid'];
//
//       // Function to fetch prescriptions for the patient
//       Future<void> fetchPrescriptions() async {
//         // Query all prescriptions for the patient
//         final prescriptionsSnapshot = await FirebaseFirestore.instance
//             .collection('patients')
//             .doc(pid.toString())
//             .collection('prescriptions')
//             .orderBy('timestamp', descending: true) // Order by timestamp to get the latest prescription
//             .get();
//
//         // Check if there are any prescriptions
//         if (prescriptionsSnapshot.docs.isNotEmpty) {
//           // List to hold prescription card widgets
//           List<Widget> prescriptionCards = [];
//
//           // Iterate through prescription documents
//           prescriptionsSnapshot.docs.forEach((prescriptionDoc) {
//             // Get prescription data and timestamp
//             Map<String, dynamic> prescriptionData = prescriptionDoc.data();
//             Timestamp timestamp = prescriptionData['timestamp'];
//
//             // Format timestamp
//             String formattedTimestamp = DateFormat.yMd().add_Hm().format(timestamp.toDate());
//
//             // Create card widget for prescription
//             Widget prescriptionCard = Card(
//               elevation: 3,
//               margin: EdgeInsets.symmetric(vertical: 8),
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Prescription: ${prescriptionData['prescription']}'),
//                     SizedBox(height: 8),
//                     Text('Time and Date: $formattedTimestamp'),
//                   ],
//                 ),
//               ),
//             );
//
//             // Add prescription card to the list
//             prescriptionCards.add(prescriptionCard);
//           });
//
//           // Show the dialog with prescription cards inside a scrollable view
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: Text('Patient Details'),
//                 content: SingleChildScrollView( // Wrap in SingleChildScrollView
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ...prescriptionCards,
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('Close'),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           // If no prescriptions found, show dialog without prescription data
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: Text('Patient Details'),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('Patient ID: ${appointmentData['pid']?.toString() ?? 'Unknown'}'),
//                     Text('Name: ${appointmentData['name'] ?? 'Unknown'}'),
//                     Text('Age: ${appointmentData['age']?.toString() ?? 'Unknown'}'),
//                     Text('Disease: ${appointmentData['disease'] ?? 'Unknown'}'),
//                     Text('Gender: ${appointmentData['gender'] ?? 'Unknown'}'),
//                     Text('Phone Number: ${appointmentData['phoneNumber'] ?? 'Unknown'}'),
//                     Text('Time and Date: ${formattedTimestamp(appointmentData)}'),
//                     SizedBox(height: 16),
//                     Text('No prescription available'),
//                   ],
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('Close'),
//                   ),
//                 ],
//               );
//             },
//           );
//         }
//       }
//
//
//
//       // Show dialog with option to view prescriptions
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Patient Details'),
//             content: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('Patient ID: ${appointmentData['pid']?.toString() ?? 'Unknown'}'),
//                 Text('Name: ${appointmentData['name'] ?? 'Unknown'}'),
//                 Text('Age: ${appointmentData['age']?.toString() ?? 'Unknown'}'),
//                 Text('Disease: ${appointmentData['disease'] ?? 'Unknown'}'),
//                 Text('Gender: ${appointmentData['gender'] ?? 'Unknown'}'),
//                 Text('Phone Number: ${appointmentData['phoneNumber'] ?? 'Unknown'}'),
//                 Text('Time and Date: ${formattedTimestamp(appointmentData)}'),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text('Close'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   // Fetch and display prescriptions
//                   fetchPrescriptions();
//                 },
//                 child: Text('View Prescriptions'),
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       print('Error fetching prescriptions: $e');
//       // Handle error as needed
//     }
//   }
//
//
//
//
//   void _viewPrescription(BuildContext context, int? pid) async {
//     try {
//       // Query the prescriptions collection for the given patient PID
//       final prescriptionSnapshot = await FirebaseFirestore.instance
//           .collection('patients')
//           .doc(pid.toString())
//           .collection('prescriptions')
//           .orderBy('timestamp', descending: true) // Order by timestamp to get the latest prescription
//           .limit(1) // Limit to the latest prescription
//           .get();
//
//       if (prescriptionSnapshot.docs.isNotEmpty) {
//         // Get the prescription data
//         final prescriptionData = prescriptionSnapshot.docs.first.data();
//
//         // Show the prescription in a dialog
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text('Prescription'),
//               content: Text(prescriptionData['prescription'] ?? 'No prescription available'),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Close'),
//                 ),
//               ],
//             );
//           },
//         );
//       } else {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text('Prescription'),
//               content: Text('No prescription available'),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Close'),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     } catch (e) {
//       print('Error fetching prescription: $e');
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text('Error'),
//             content: Text('Failed to fetch prescription. Please try again later.'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text('Close'),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
//
//
//
//   Future<void> _fetchPatientData() async {
//     try {
//       // Implement the logic to fetch patient data using FirebaseService
//       await FirebaseService.fetchPatientData();
//     } catch (e) {
//       print('Error fetching patient data: $e');
//       // Handle error as needed
//     }
//   }
//   void _savePrescription(int pid, String prescription) async {
//     try {
//       // Get a reference to the patient's document
//       final patientRef = FirebaseFirestore.instance.collection('patients').doc(pid.toString());
//
//       // Add the prescription as a sub-collection with a custom document ID
//       final prescriptionDocRef = patientRef.collection('prescriptions').doc();
//
//       // Set the data for the prescription document
//       await prescriptionDocRef.set({
//         'prescription': prescription,
//         'timestamp': DateTime.now(), // You may want to add a timestamp for when the prescription was saved
//       });
//
//       print('Prescription saved successfully for patient with ID: $pid');
//     } catch (e) {
//       print('Error saving prescription: $e');
//       // Handle error as needed
//     }
//   }
//
//
//
//
//
// }