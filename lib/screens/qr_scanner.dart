// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
//
// class Dashboard extends StatefulWidget {
//   const Dashboard({Key? key}) : super(key: key);
//
//   @override
//   _DashboardState createState() => _DashboardState();
// }
//
// class _DashboardState extends State<Dashboard> {
//   late Stream<QuerySnapshot> _customersStream;
//   late Map<String, List<DocumentSnapshot>> stylistAppointments;
//   String selectedStylist = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _customersStream = FirebaseFirestore.instance.collection('Users').snapshots();
//   }
//
//   void updateDashboardState() {
//     setState(() {});
//   }
//
//   Future<void> markServiceDone(
//       String documentID,
//       bool isServiceDone,
//       Function(Map<String, dynamic> appointmentData) onServiceDone,
//       ) async {
//     try {
//       final appointmentSnapshot = await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(documentID)
//           .get();
//       final appointmentData =
//       appointmentSnapshot.data() as Map<String, dynamic>;
//
//       await FirebaseFirestore.instance
//           .collection('History')
//           .doc(documentID)
//           .set({
//         ...appointmentData,
//         'completed': isServiceDone,
//       });
//
//       await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(documentID)
//           .update({
//         'completed': isServiceDone,
//       });
//
//       onServiceDone(appointmentData);
//
//       // Stay on the same page by refreshing the UI
//       setState(() {});
//     } catch (error) {
//       print("Error marking service done: $error");
//     }
//   }
//
//   Future<void> markServiceNotDone(
//       String documentID,
//       Function(Map<String, dynamic> appointmentData) onServiceNotDone,
//       ) async {
//     try {
//       final appointmentSnapshot = await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(documentID)
//           .get();
//       final appointmentData =
//       appointmentSnapshot.data() as Map<String, dynamic>;
//
//       await FirebaseFirestore.instance
//           .collection('History')
//           .doc(documentID)
//           .set({
//         ...appointmentData,
//         'completed': false,
//       });
//
//       await FirebaseFirestore.instance
//           .collection('Users')
//           .doc(documentID)
//           .delete();
//
//       onServiceNotDone(appointmentData);
//       setState(() {});
//     } catch (error) {
//       print("Error marking service not done: $error");
//     }
//   }
//
//   Map<String, List<DocumentSnapshot>> groupAppointmentsByStylist(
//       List<DocumentSnapshot> appointments,
//       ) {
//     Map<String, List<DocumentSnapshot>> stylistAppointments = {};
//
//     for (var appointment in appointments) {
//       final data = appointment.data() as Map<String, dynamic>;
//       final stylistName = data['stylistName'];
//
//       if (!stylistAppointments.containsKey(stylistName)) {
//         stylistAppointments[stylistName] = [];
//       }
//
//       stylistAppointments[stylistName]!.add(appointment);
//     }
//
//     return stylistAppointments;
//   }
//
//   Future<void> updateAppointmentStatusAndSendTwilio(
//       String stylistName,
//       String status,
//       Map<String, dynamic> appointment,
//       ) async {
//     try {
//       // Perform the update in Firestore
//       await updateAppointmentStatus(stylistName, status);
//
//       // Fetch the user's phone number from Firestore
//       String userPhoneNumber = '+91' + appointment['phoneNumber'];
//
//       // Send Twilio SMS
//       String message = status == 'accepted'
//           ? 'Your appointment with $stylistName has been accepted.'
//           : 'Your appointment with $stylistName has been declined.';
//
//       await sendTwilioSMS(
//         to: userPhoneNumber,
//         body: message,
//         stylistName: stylistName,
//       );
//
//       // Fetch updated appointments after the update
//       fetchAppointmentsByStylist(stylistName);
//     } catch (error) {
//       print('Error updating appointment status and sending SMS: $error');
//     }
//   }
//
//   Future<void> sendTwilioSMS({
//     required String to,
//     required String body,
//     required String stylistName,
//   }) async {
//     try {
//       final accountSid = 'AC45d39b3d898206fef90d4ed67fb4a7bc';
//       final authToken = 'e11f5cbb9d964b9cfe63d93fa9f97da6';
//       final twilioNumber = '+12816168209';
//
//       // Fetch the latest appointment details from Firestore based on stylist name
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('Users')
//           .where('stylistName', isEqualTo: stylistName)
//           .limit(1)
//           .get();
//
//       if (querySnapshot.docs.isNotEmpty) {
//         final appointmentDetails =
//         querySnapshot.docs.first.data() as Map<String, dynamic>;
//
//         // Construct Twilio API endpoint
//         final apiUrl =
//             'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json';
//
//         // Construct message body with appointment details
//         final formattedBody = '$body\n\nAppointment Details:\n'
//             'Customer Name: ${appointmentDetails['name']}\n'
//             'Phone Number: ${appointmentDetails['phoneNumber']}\n'
//             'Booking Slot: ${appointmentDetails['selectedTimeSlots']}\n'
//             'Date: ${DateFormat('yyyy-MM-dd').format(appointmentDetails['selectedDate']?.toDate() ?? DateTime.now())}';
//
//         // Make an HTTP POST request to Twilio API
//         final response = await http.post(
//           Uri.parse(apiUrl),
//           headers: {
//             'Authorization':
//             'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
//           },
//           body: {
//             'From': twilioNumber,
//             'To': to,
//             'Body': formattedBody,
//           },
//         );
//
//         // Check the response status
//         if (response.statusCode == 201) {
//           print('SMS sent successfully');
//         } else {
//           print('Failed to send SMS. Status code: ${response.statusCode}');
//           print('Response body: ${response.body}');
//         }
//       } else {
//         print('No appointment found for stylist $stylistName');
//       }
//     } catch (error) {
//       print('Error sending SMS: $error');
//     }
//   }
//
//   Future<void> updateAppointmentStatus(
//       String stylistName,
//       String status,
//       ) async {
//     try {
//       CollectionReference usersCollection =
//       FirebaseFirestore.instance.collection('Users');
//
//       // Query for appointments with the matching stylist name and 'pending' status
//       QuerySnapshot querySnapshot = await usersCollection
//           .where('stylistName', isEqualTo: stylistName)
//           .where('status', isEqualTo: 'pending')
//           .get();
//       if (querySnapshot.docs.isNotEmpty) {
//         DocumentSnapshot appointmentDoc = querySnapshot.docs.first;
//
//         await appointmentDoc.reference.update({'status': status});
//
//         print(
//             'Appointment status updated successfully to $status for stylist $stylistName');
//       } else {
//         print('No pending appointment found for stylist $stylistName');
//       }
//     } catch (error) {
//       print('Error updating appointment status: $error');
//     }
//   }
//
//   void fetchAppointmentsByStylist(String stylistName) {
//     print('Fetching appointments for $stylistName');
//     setState(() {
//       selectedStylist = stylistName;
//     });
//   }
//
//   void fetchAllAppointments() async {
//     try {
//       QuerySnapshot querySnapshot =
//       await FirebaseFirestore.instance.collection('Users').get();
//
//       setState(() {
//         stylistAppointments = {};
//         for (QueryDocumentSnapshot doc in querySnapshot.docs) {
//           String stylistName = doc['stylistName'];
//           if (!stylistAppointments.containsKey(stylistName)) {
//             stylistAppointments[stylistName] = [];
//           }
//           stylistAppointments[stylistName]!.add(
//             doc,
//           );
//         }
//       });
//     } catch (error) {
//       print("Error fetching appointments: $error");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: StreamBuilder<QuerySnapshot>(
//             stream: _customersStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               final appointments = snapshot.data?.docs ?? [];
//               stylistAppointments = groupAppointmentsByStylist(appointments);
//
//               return Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: Text(
//                         "Admin Dashboard",
//                         style: GoogleFonts.openSans(
//                           textStyle: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 25,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 15),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       for (var stylistName in stylistAppointments.keys)
//                         ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               selectedStylist = stylistName;
//                             });
//                           },
//                           child: Text(
//                             stylistName,
//                             style: TextStyle(
//                               color: selectedStylist == stylistName
//                                   ? Colors.white
//                                   : Colors.black,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             foregroundColor: Colors.white,
//                             backgroundColor: selectedStylist == stylistName
//                                 ? Colors.brown[300]
//                                 : null,
//                           ),
//                         ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   if (selectedStylist.isNotEmpty &&
//                       (stylistAppointments[selectedStylist] == null ||
//                           stylistAppointments[selectedStylist]!.isEmpty))
//                     Center(
//                       child: Text('No Appointments'),
//                     )
//                   else if (selectedStylist.isNotEmpty)
//                     Container(
//                       color: Colors.grey[200],
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Text(
//                               'Upcoming Appointments - $selectedStylist',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           ListView.builder(
//                             shrinkWrap: true,
//                             physics: NeverScrollableScrollPhysics(),
//                             itemCount: stylistAppointments[selectedStylist]!.length,
//                             itemBuilder: (context, index) {
//                               final appointment =
//                               stylistAppointments[selectedStylist]![index];
//
//                               final isCompleted =
//                                   appointment.data() is Map<String, dynamic> &&
//                                       (appointment.data() as Map<String, dynamic>)
//                                           .containsKey('completed') &&
//                                       (appointment.data()
//                                       as Map<String, dynamic>)['completed'];
//
//                               return isCompleted
//                                   ? Container()
//                                   : Card(
//                                 margin: EdgeInsets.symmetric(
//                                     vertical: 8, horizontal: 16),
//                                 child: ListTile(
//                                   title: Text(appointment['name']),
//                                   subtitle: Column(
//                                     crossAxisAlignment:
//                                     CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Booking Slot: ${appointment['selectedTimeSlots']}',
//                                       ),
//                                       Text(
//                                         'Total Amount: ${appointment['totalAmount']}',
//                                       ),
//                                       Text(
//                                         'Date: ${DateFormat('yyyy-MM-dd HH:mm').format((appointment['selectedDate'] as Timestamp).toDate())}',
//                                       ),
//                                       SizedBox(height: 5),
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           ElevatedButton(
//                                             onPressed: () {
//                                               // Accept button logic
//                                               updateAppointmentStatusAndSendTwilio(
//                                                 selectedStylist,
//                                                 'accepted',
//                                                 appointment.data() as Map<String, dynamic>,
//                                               );
//                                             },
//                                             child: Text('Accept'),
//                                           ),
//                                           ElevatedButton(
//                                             onPressed: () {
//                                               // Decline button logic
//                                               updateAppointmentStatusAndSendTwilio(
//                                                 selectedStylist,
//                                                 'declined',
//                                                 appointment.data() as Map<String, dynamic>,
//                                               );
//                                             },
//                                             child: Text('Decline'),
//
//
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: 5),
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           ElevatedButton(
//                                             onPressed: () {
//                                               markServiceDone(
//                                                 appointment.id,
//                                                 true,
//                                                     (appointmentData) {
//                                                   updateDashboardState();
//                                                 },
//                                               );
//                                             },
//                                             child: Text('Service Done'),
//                                           ),
//                                           ElevatedButton(
//                                             onPressed: () {
//                                               markServiceNotDone(
//                                                 appointment.id,
//                                                     (appointmentData) {
//                                                   updateDashboardState();
//                                                 },
//                                               );
//                                             },
//                                             child: Text('Service not Done'),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             },
//        ),
//     );
//     }
// }