// Import statements
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:html' as html;

import '../../../services/firebase_service.dart'; // Import dart:html for web-specific functionalities

// Define extension for DateTime
extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return this.year == other.year &&
        this.month == other.month &&
        this.day == other.day;
  }
}

// TodaysAppointment Widget
class TodaysAppointment extends StatefulWidget {
  @override
  _TodaysAppointmentState createState() => _TodaysAppointmentState();
}

// _TodaysAppointmentState class
class _TodaysAppointmentState extends State<TodaysAppointment> {
  // State variables
  Color myBlueColor = Color(0xFF13395E);
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool _showSearchBar = false;
  int tokenCounter = 1;
  List<Map<String, dynamic>> todaysAppointments = [];

  // Method to fetch today's appointments
  Future<List<Map<String, dynamic>>> _fetchTodaysAppointments() async {
    try {
      // Fetch all appointments from Firebase
      List<Map<String, dynamic>> allAppointments =
      await FirebaseService.fetchPatientData();

      // Filter appointments for today
      DateTime today = DateTime.now();
      todaysAppointments = allAppointments.where((appointment) {
        DateTime appointmentDate =
        (appointment['timestamp'] as Timestamp).toDate();
        return today.isSameDate(appointmentDate);
      }).toList();

      // Filter appointments based on the search query
      String searchQuery = searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        searchResults = todaysAppointments.where((appointment) =>
        appointment['name']
            .toLowerCase()
            .contains(searchQuery) ||
            appointment['disease']
                .toLowerCase()
                .contains(searchQuery) ||
            appointment['pid'].toString().contains(searchQuery)).toList();
        return searchResults;
      }

      // Sort appointments by patient ID
      todaysAppointments.sort((a, b) {
        int idA = a['pid'] as int? ?? 0;
        int idB = b['pid'] as int? ?? 0;
        return idA.compareTo(idB);
      });

      return todaysAppointments;
    } catch (e) {
      print('Error fetching today\'s appointments: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todays Appointments',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust the horizontal padding as needed
            child: IconButton(
              icon: Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) {
                    searchController.clear();
                    searchResults.clear();
                  }
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust the horizontal padding as needed
            child: IconButton(
              icon: Icon(Icons.download),
              color: Colors.white,
              onPressed: () async {
                // Fetch today's appointments
                List<Map<String, dynamic>> todaysAppointments =
                await _fetchTodaysAppointments();
                // Call the download method
                _downloadPatientDataAsCSV(todaysAppointments);
              },
            ),
          ),
        ],
        backgroundColor: myBlueColor,
      ),

      body: Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search by ID, Name, or Disease',
                ),
                onChanged: (query) {
                  setState(() {
                    searchResults = _performSearch(query);
                  });
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTodaysAppointments(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> appointments =
                    snapshot.data ?? searchResults ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (appointments.isEmpty) {
                  return Center(child: Text('No appointments for today.'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Container(
                      height: 300,
                      width: 1000,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: PaginatedDataTable(
                          dataRowMinHeight: 50,
                          dataRowMaxHeight: 50,
                          rowsPerPage: 5,
                          columns: [
                            DataColumn(
                              label: Text('Patient ID',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Disease',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Time and Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Prescription', // New column for prescription
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Send Message',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                            DataColumn(
                              label: Text('Actions',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ),
                          ],
                          source: TodaysAppointmentDataSource(
                            appointments,
                            context,
                            _fetchTodaysAppointments,
                            _sendMessages,
                            _incrementTokenCounter,
                            _savePrescription, // Pass the function to save prescription
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Method to perform search
  List<Map<String, dynamic>> _performSearch(String query) {
    return todaysAppointments.where((appointment) =>
    appointment['name'].toLowerCase().contains(query.toLowerCase()) ||
        appointment['disease'].toLowerCase().contains(query.toLowerCase()) ||
        appointment['pid'].toString().contains(query)).toList();
  }

  // Method to send messages
  void _sendMessages(String phoneNumber, int tokenNumber) async {
    // Implementation goes here
  }

  // Method to save prescription
  void _savePrescription(int pid, String prescription) async {
    // Implementation goes here
  }

  // Method to increment token counter
  void _incrementTokenCounter() {
    // Implementation goes here
  }

  // Method to download patient data as CSV
  Future<void> _downloadPatientDataAsCSV(
      List<Map<String, dynamic>> patientDataList) async {
    try {
      // Check if the platform is supported for accessing directories
      if (!kIsWeb) {
        throw UnsupportedError(
            'File operations are only supported on web platforms.');
      }

      // Create a CSV string with headers
      String csv =
          'Patient ID,Name,Age,Disease,Gender,Phone Number,Time and Date\n';

      // Append each patient's data to the CSV string
      for (var patient in patientDataList) {
        csv +=
        '${patient['pid']},${patient['name']},${patient['age']},${patient['disease']},${patient['gender']},${patient['phoneNumber']},${_formattedTimestamp(patient)}\n';
      }

      // Convert the CSV string to a Blob
      final blob = html.Blob([csv]);

      // Create an object URL for the Blob
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a link element
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'patient_data.csv')
        ..click(); // Simulate click to download the file

      // Revoke the object URL to free up memory
      html.Url.revokeObjectUrl(url);

      // Show a dialog to inform the user that the download is complete
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Download Complete'),
            content: Text('Patient data has been downloaded as CSV.'),
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
    } catch (e) {
      print('Error downloading patient data: $e');
      // Handle the error gracefully
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Failed to download patient data. Please try again later.'),
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

  // Method to format timestamp
  String _formattedTimestamp(Map<String, dynamic> patientData) {
    Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
    DateTime? dateTime = timestamp?.toDate();
    return dateTime != null ? DateFormat.yMd().add_Hm().format(dateTime) : '';
  }
}

// TodaysAppointmentDataSource class
class TodaysAppointmentDataSource extends DataTableSource {
  // Instance variables
  final List<Map<String, dynamic>> _data;
  final BuildContext context;
  final Future<List<Map<String, dynamic>>> Function() fetchAppointments;
  final Function(String, int) sendMessage;
  final Function() incrementTokenCounter;
  final Function(int, String) savePrescription;

  // Constructor
  TodaysAppointmentDataSource(
      this._data,
      this.context,
      this.fetchAppointments,
      this.sendMessage,
      this.incrementTokenCounter,
      this.savePrescription,
      );
  int tokenCounter = 1;

  @override
  DataRow getRow(int index) {
    final appointmentData = _data[index];
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () {
              _showDetailsDialog(context, appointmentData);
            },
            child: Text(appointmentData['pid']?.toString() ?? 'Unknown'),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () {
              _showDetailsDialog(context, appointmentData);
            },
            child: Text(appointmentData['name'] ?? 'Unknown'),
          ),
        ),
        DataCell(Text(appointmentData['disease'] ?? 'Unknown')),
        DataCell(Text(formattedTimestamp(appointmentData))),
        DataCell(
          IconButton(
            icon: Icon(Icons.medical_information_outlined),
            onPressed: () {
              _showPrescriptionModal(context, appointmentData['pid'], index); // Pass index here
            },
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.message),
                onPressed: () {
                  String phoneNumber = appointmentData['phoneNumber'];
                  if (phoneNumber != null) {
                    sendMessage(phoneNumber, ++tokenCounter);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Phone Number Not Available'),
                          content: Text(
                              'The phone number for this appointment is not available.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
              IconButton(
                icon: Image.asset(
                  'assets/images/whatsapp.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        DataCell(
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteAppointment(appointmentData['pid']);
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;

  String formattedTimestamp(Map<String, dynamic> patientData) {
    Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
    DateTime? dateTime = timestamp?.toDate();
    return dateTime != null
        ? DateFormat.yMd().add_Hm().format(dateTime)
        : 'N/A';
  }


  void _deleteAppointment(int? pid) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete this appointment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        print('Deleting appointment with pid: $pid');
        // Implement the logic to delete the appointment using FirebaseService
        await FirebaseService.deleteAppointment(pid);
        print('Appointment deleted successfully');
        // After deletion, you might want to refresh the appointment data
        _fetchPatientData();
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      // Handle error as needed
    }
  }

  void _showPrescriptionModal(BuildContext context, int pid, int index) {
    String prescription = ''; // State to hold the prescription text

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Write Prescription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: TextFormField(
                      initialValue: prescription,
                      maxLines: null, // Allow the TextFormField to expand vertically
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter prescription',
                      ),
                      onChanged: (value) {
                        prescription = value;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    // Save the prescription to the database for the particular patient (pid)
                    _savePrescription(pid, prescription);
                    Navigator.pop(context); // Close the modal
                  },
                  child: Text('Save Prescription'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> appointmentData) async {
    try {
      // Get the patient ID from the appointment data
      int? pid = appointmentData['pid'];

      // Function to fetch prescriptions for the patient
      Future<void> fetchPrescriptions() async {
        // Query all prescriptions for the patient
        final prescriptionsSnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .doc(pid.toString())
            .collection('prescriptions')
            .orderBy('timestamp', descending: true) // Order by timestamp to get the latest prescription
            .get();

        // Check if there are any prescriptions
        if (prescriptionsSnapshot.docs.isNotEmpty) {
          // List to hold prescription card widgets
          List<Widget> prescriptionCards = [];

          // Iterate through prescription documents
          prescriptionsSnapshot.docs.forEach((prescriptionDoc) {
            // Get prescription data and timestamp
            Map<String, dynamic> prescriptionData = prescriptionDoc.data();
            Timestamp timestamp = prescriptionData['timestamp'];

            // Format timestamp
            String formattedTimestamp = DateFormat.yMd().add_Hm().format(timestamp.toDate());

            // Create card widget for prescription
            // Create card widget for prescription
            Widget prescriptionCard = Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prescription: ${prescriptionData['prescription']}'),
                    SizedBox(height: 8),
                    Text('Time and Date: $formattedTimestamp'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Show dialog to edit prescription
                            _showPrescriptionEditDialog(context, pid!, prescriptionData['prescription']);
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/images/whatsapp.png', // Assuming you have a WhatsApp icon asset
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {
                            // Implement sending prescription via WhatsApp
                            String phoneNumber = appointmentData['phoneNumber'];
                            if (phoneNumber != null) {
                              _sendPrescriptionViaWhatsApp(phoneNumber, prescriptionData['prescription']);
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Phone Number Not Available'),
                                    content: Text(
                                      'The phone number for this appointment is not available.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete), // Delete icon
                          onPressed: () {
                            // Show confirmation dialog before deleting prescription
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirm Deletion'),
                                  content: Text('Are you sure you want to delete this prescription?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close confirmation dialog
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Delete prescription and close confirmation dialog
                                        _deletePrescription(pid.toString(), prescriptionDoc.id);

                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );


            // Add prescription card to the list
            prescriptionCards.add(prescriptionCard);
          });

          // Show the dialog with prescription cards inside a scrollable view
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Patient Details'),
                content: SingleChildScrollView( // Wrap in SingleChildScrollView
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...prescriptionCards,
                    ],
                  ),
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
        } else {
          // If no prescriptions found, show dialog without prescription data
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Patient Details'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Patient ID: ${appointmentData['pid']?.toString() ?? 'Unknown'}'),
                    Text('Name: ${appointmentData['name'] ?? 'Unknown'}'),
                    Text('Age: ${appointmentData['age']?.toString() ?? 'Unknown'}'),
                    Text('Disease: ${appointmentData['disease'] ?? 'Unknown'}'),
                    Text('Gender: ${appointmentData['gender'] ?? 'Unknown'}'),
                    Text('Phone Number: ${appointmentData['phoneNumber'] ?? 'Unknown'}'),
                    Text('Time and Date: ${formattedTimestamp(appointmentData)}'),
                    SizedBox(height: 16),
                    Text('No prescription available'),
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

      // Show dialog with option to view prescriptions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Patient Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Patient ID: ${appointmentData['pid']?.toString() ?? 'Unknown'}'),
                Text('Name: ${appointmentData['name'] ?? 'Unknown'}'),
                Text('Age: ${appointmentData['age']?.toString() ?? 'Unknown'}'),
                Text('Disease: ${appointmentData['disease'] ?? 'Unknown'}'),
                Text('Gender: ${appointmentData['gender'] ?? 'Unknown'}'),
                Text('Phone Number: ${appointmentData['phoneNumber'] ?? 'Unknown'}'),
                Text('Time and Date: ${formattedTimestamp(appointmentData)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  // Fetch and display prescriptions
                  fetchPrescriptions();
                },
                child: Row(
                  children: [
                    Icon(Icons.description), // Icon instead of text
                    SizedBox(width: 8),
                    Text('View Prescriptions'),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching prescriptions: $e');
      // Handle error as needed
    }
  }

// Method to send prescription via WhatsApp
  void _sendPrescriptionViaWhatsApp(String phoneNumber, String prescription) async {
    try {
      String encodedPrescription = Uri.encodeFull(prescription);
      String whatsappUrl = "https://wa.me/$phoneNumber?text=$encodedPrescription";

      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      print('Error sending prescription via WhatsApp: $e');
      // Handle error as needed
    }
  }




  void _showPrescriptionEditDialog(BuildContext context, int pid, String currentPrescription) {
    String editedPrescription = currentPrescription; // Initialize the editedPrescription with the currentPrescription

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Prescription'),
          content: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            controller: TextEditingController(text: currentPrescription), // Use TextEditingController to control the text field
            onChanged: (value) {
              editedPrescription = value; // Update the editedPrescription when the text changes
            },
            decoration: InputDecoration(
              hintText: 'Enter the updated prescription',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call function to save the edited prescription
                _savePrescription(pid, editedPrescription); // Pass the edited prescription
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }






  void _viewPrescription(BuildContext context, int? pid) async {
    try {
      // Query the prescriptions collection for the given patient PID
      final prescriptionSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(pid.toString())
          .collection('prescriptions')
          .orderBy('timestamp', descending: true) // Order by timestamp to get the latest prescription
          .limit(1) // Limit to the latest prescription
          .get();

      if (prescriptionSnapshot.docs.isNotEmpty) {
        // Get the prescription data
        final prescriptionData = prescriptionSnapshot.docs.first.data();

        // Show the prescription in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Prescription'),
              content: Text(prescriptionData['prescription'] ?? 'No prescription available'),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Prescription'),
              content: Text('No prescription available'),
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
    } catch (e) {
      print('Error fetching prescription: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch prescription. Please try again later.'),
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

  Future<void> _fetchPatientData() async {
    try {
      // Implement the logic to fetch patient data using FirebaseService
      await FirebaseService.fetchPatientData();
    } catch (e) {
      print('Error fetching patient data: $e');
      // Handle error as needed
    }
  }
// Method to save prescription
  void _savePrescription(int pid, String prescription) async {
    try {
      // Get a reference to the patient's document
      final patientRef = FirebaseFirestore.instance.collection('patients').doc(
          pid.toString());

      // Query the prescriptions collection for the given patient PID
      final prescriptionsSnapshot = await patientRef
          .collection('prescriptions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (prescriptionsSnapshot.docs.isNotEmpty) {
        // Update the existing prescription document
        final existingPrescriptionDoc = prescriptionsSnapshot.docs.first;
        await existingPrescriptionDoc.reference.update({
          'prescription': prescription,
          'timestamp': DateTime.now(),
        });
        print('Prescription updated successfully for patient with ID: $pid');
      } else {
        // If no existing prescription found, do nothing or handle it as needed
        print('No existing prescription found for patient with ID: $pid');
      }

      // Refresh UI by calling fetchAppointments
      await fetchAppointments();
    } catch (e) {
      print('Error saving prescription: $e');
      // Handle error as needed
    }
  }

  Future<void> _deletePrescription(String pid, String prescriptionId) async {
    try {
      // Delete the prescription document from Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(pid) // Use the provided patient ID
          .collection('prescriptions')
          .doc(prescriptionId)
          .delete();
      // Print a message indicating successful deletion (optional)
      print('Prescription deleted successfully.');
    } catch (error) {
      // Handle any errors that occur during deletion
      print('Error deleting prescription: $error');
      // You might want to show an error message to the user here
    }
  }




}