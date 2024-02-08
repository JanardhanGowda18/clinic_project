// Import statements
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import '../../services/firebase_service.dart';
import 'DialogUtils.dart';
import 'dart:convert';
import 'dart:html' as html; // Import dart:html for web-specific functionalities

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
          IconButton(
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
          IconButton(
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
            icon: Icon(Icons.edit),
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








  void _showDetailsDialog(BuildContext context,
      Map<String, dynamic> appointmentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Patient Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Patient ID: ${appointmentData['pid']?.toString() ??
                      'Unknown'}'),
              Text('Name: ${appointmentData['name'] ?? 'Unknown'}'),
              Text('Age: ${appointmentData['age']?.toString() ?? 'Unknown'}'),
              Text('Disease: ${appointmentData['disease'] ?? 'Unknown'}'),
              Text('Gender: ${appointmentData['gender'] ?? 'Unknown'}'),
              Text('Phone Number: ${appointmentData['phoneNumber'] ??
                  'Unknown'}'),
              Text('Time and Date: ${formattedTimestamp(appointmentData)}'),
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

  Future<void> _fetchPatientData() async {
    try {
      // Implement the logic to fetch patient data using FirebaseService
      await FirebaseService.fetchPatientData();
    } catch (e) {
      print('Error fetching patient data: $e');
      // Handle error as needed
    }
  }
  void _savePrescription(int pid, String prescription) async {
    try {
      // Get a reference to the patient's document
      final patientRef = FirebaseFirestore.instance.collection('patients').doc(pid.toString());

      // Add the prescription as a sub-collection with a custom document ID
      final prescriptionDocRef = patientRef.collection('prescriptions').doc();

      // Set the data for the prescription document
      await prescriptionDocRef.set({
        'prescription': prescription,
        'timestamp': DateTime.now(), // You may want to add a timestamp for when the prescription was saved
      });

      print('Prescription saved successfully for patient with ID: $pid');
    } catch (e) {
      print('Error saving prescription: $e');
      // Handle error as needed
    }
  }




}