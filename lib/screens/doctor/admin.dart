import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import 'DialogUtils.dart';
import 'doctor_login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:html' as html;

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Color myBlueColor = Color(0xFF13395E);
  List<Map<String, dynamic>> patientDataList = [];
  String selectedDisease = '';
  String searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  TextEditingController searchController = TextEditingController();
  bool _showSearchBar = false;
  double tableWidth = 1000;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
    _onShowAllPatients1();

    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  Widget _buildSearchBar() {
    return _showSearchBar
        ? TextField(
      controller: searchController,
      onChanged: (query) {
        _searchPatients();
      },
      decoration: InputDecoration(
        hintText: 'Search Patient ID, Name, or Disease',
      ),
    )
        : Container();
  }


  Future<void> _fetchPatientData() async {
    try {
      List<Map<String, dynamic>> data = await FirebaseService
          .fetchPatientData();
      // Sort the patient data based on timestamp in ascending order
      data.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      setState(() {
        patientDataList = data;
      });

      // After fetching the data, trigger the method to show all patients
      _onShowAllPatients1();
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Function to generate a unique pid
  int generateUniquePid() {
    List<int> usedPids = patientDataList.map((patient) {
      return patient['pid'] as int? ?? 0;
    }).toList();

    int newPid = 1;
    while (usedPids.contains(newPid)) {
      newPid++;
    }

    return newPid;
  }

  Future<void> addPatientData(Map<String, dynamic> data) async {
    // Generate a unique pid
    int newPid = generateUniquePid();
    await FirebaseFirestore.instance.collection('patients').doc().set({
      ...data,
      'pid': newPid,
    });
  }

  String formattedTimestamp(Map<String, dynamic> patientData) {
    Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
    DateTime? dateTime = timestamp?.toDate();
    return dateTime != null
        ? DateFormat.yMd().add_Hm().format(dateTime)
        : 'N/A';
  }


  void _onDiseaseCardTap(String disease) {
    setState(() {
      selectedDisease = disease;
    });
  }

  void _onShowAllPatients1() {
    setState(() {
      selectedDisease = '';
      _filterPatientsByDate1(); // Keep this line to ensure all patients are displayed
    });
  }


  List<Map<String, dynamic>> filteredPatientData = [];


  void _filterPatientsByDate(DateTime? selectedDate) {
    // Filter patient data based on selected date
    filteredPatientData = patientDataList.toList();

    if (selectedDate != null) {
      filteredPatientData = patientDataList
          .where((patient) {
        if (patient['timestamp'] != null) {
          DateTime patientDate = (patient['timestamp'] as Timestamp).toDate();
          return patientDate.year == selectedDate.year &&
              patientDate.month == selectedDate.month &&
              patientDate.day == selectedDate.day;
        }
        return false;
      })
          .toList();
    }

    setState(() {});
  }

  void _filterPatientsByDate1() {
    // Filter patient data based on selected date
    filteredPatientData = patientDataList.toList();
    setState(() {});
  }


  void _showDatePicker() async {
    DateTime fiveYearsAgo = DateTime.now().subtract(
        Duration(days: 5 * 365)); // Adjust the number of years as needed
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(fiveYearsAgo.year, 1, 1),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _filterPatientsByDate(_selectedDate);
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              _showDatePicker();
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            color: Colors.white,
            onPressed: () {
              _downloadPatientDataAsCSV(); // Call the download method
            },
          ),
        ],
        backgroundColor: myBlueColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSearchBar(),
            ),
            // Use a SingleChildScrollView with horizontal scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (patientDataList.isEmpty) {
                    return Text('No patients registered.');
                  }

                  List<Map<String, dynamic>> filteredData =
                  selectedDisease.isEmpty
                      ? filteredPatientData
                      : filteredPatientData
                      .where((patient) =>
                  patient['disease'] == selectedDisease)
                      .toList();

                  if (selectedDisease.isNotEmpty && filteredData.isEmpty) {
                    return Text(
                        'No patients registered for $selectedDisease.');
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Opacity(
                      opacity: _animation.value,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: tableWidth,
                          child: PaginatedDataTable(
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
                              // DataColumn(
                              //   label: Text('Send message',
                              //       style: TextStyle(
                              //           fontWeight: FontWeight.bold,
                              //           fontSize: 18)),
                              // ),
                              DataColumn(
                                label: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ),
                            ],
                            source: _PatientDataSource(
                              filteredData,
                              patientDataList, // Pass patientDataList here
                              context,
                              _deleteAppointment,
                            ),

                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showSearchDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Search Patients'),
  //         content: TextField(
  //           controller: searchController,
  //           decoration: InputDecoration(
  //             hintText: 'Enter Patient ID, Name, or Disease',
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               _searchPatients();
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Search'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               searchController.clear();
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Cancel'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _searchPatients() {
    String query = searchController.text.toLowerCase();

    if (query.isEmpty) {
      // Reset to show all patients
      _onShowAllPatients1();
    } else {
      // Filter patients based on the search query
      List<Map<String, dynamic>> searchResult = patientDataList
          .where((patient) =>
      patient['pid']
          .toString()
          .toLowerCase()
          .contains(query) ||
          patient['name'].toLowerCase().contains(query) ||
          patient['disease'].toLowerCase().contains(query))
          .toList();

      setState(() {
        filteredPatientData = searchResult;
      });
    }
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
        // After deletion, you might want to refresh the patient data
        _fetchPatientData();
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      // Handle error as needed
    }
  }


  Widget _buildDiseaseCard(String disease) {
    return GestureDetector(
      onTap: () {
        _onDiseaseCardTap(disease);
      },
      child: Card(
        color: selectedDisease == disease ? Colors.blue : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            disease,
            style: TextStyle(
              color:
              selectedDisease == disease ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPatientDataAsCSV() async {
    try {
      // Check if the platform is supported for accessing directories
      if (!kIsWeb) {
        throw UnsupportedError(
            'File operations are only supported on web platforms.');
      }

      // Create a CSV string with headers
      String csv = 'Patient ID,Name,Age,Disease,Gender,Phone Number,Time and Date\n';

      // Append each patient's data to the CSV string
      for (var patient in patientDataList) {
        csv +=
        '${patient['pid']},${patient['name']},${patient['age']},${patient['disease']},${patient['gender']},${patient['phoneNumber']},${formattedTimestamp(patient)}\n';
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


}
class _PatientDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;
  final List<Map<String, dynamic>> patientDataList; // Add patientDataList as an instance variable
  final BuildContext context; // Add context as an instance variable
  final Function(int?) deleteAppointment; // Add a callback for delete

  _PatientDataSource(this._data, this.patientDataList, this.context, this.deleteAppointment); // Update the constructor

  @override
  DataRow getRow(int index) {
    final patient = _data[index];
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () {
              _showDetailsModal(patient);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(patient['pid']?.toString() ?? ''),
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () {
              _showDetailsModal(patient);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Text(patient['name'] ?? ''),
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(patient['disease'] ?? ''),
          ),
        ),
        // DataCell(
        //   // Row(
        //   //   children: [
        //   //     // IconButton(
        //   //     //   icon: Icon(Icons.message),
        //   //     //   onPressed: () {
        //   //     //     // _sendMessages(patient['phoneNumber']);
        //   //     //   },
        //   //     // ),
        //   //     // IconButton(
        //   //     //   icon: Image.asset(
        //   //     //       'assets/images/whatsapp.png', width: 24, height: 24),
        //   //     //   onPressed: () {
        //   //     //     // _sendMessages(patient['phoneNumber']);
        //   //     //   },
        //   //     // ),
        //   //   ],
        //   // ),
        // ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  deleteAppointment(patient['pid']);
                },
              ),
              IconButton(
                icon: Icon(Icons.message),
                onPressed: () {
                  _sendMessages(patient['phoneNumber']);
                },
              ),
            ],
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
  void _showDetailsModal(Map<String, dynamic> patientData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3, // Adjust the width as needed
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left:130,top:20,bottom:20),
                          child: Text(
                            'Patient Details',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.only(left: 100, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildDetailItem('Patient ID', patientData['pid']?.toString() ?? 'Unknown'),
                          _buildDetailItem('Name', patientData['name'] ?? 'Unknown'),
                          _buildDetailItem('Age', patientData['age']?.toString() ?? 'Unknown'),
                          _buildDetailItem('Disease', patientData['disease'] ?? 'Unknown'),
                          _buildDetailItem('Gender', patientData['gender'] ?? 'Unknown'),
                          _buildDetailItem('Phone Number', patientData['phoneNumber'] ?? 'Unknown'),
                          _buildDetailItem('Time and Date', formattedTimestamp(patientData)),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 0),
                      child: ElevatedButton(
                        onPressed: () {
                          _showPreviousRegistrations(patientData);
                        },
                        child: Text('Show Previous Registrations'),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }




  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }



  void _showPreviousRegistrations(Map<String, dynamic> patientData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Previous Registrations'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildPreviousRegistrations(patientData),
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

// Helper method to build previous registration details
  List<Widget> _buildPreviousRegistrations(Map<String, dynamic> patientData) {
    List<Widget> widgets = [];

    // Filter previous registrations for the same phone number and name
    List<Map<String, dynamic>> previousRegistrations = patientDataList.where((patient) =>
    patient['phoneNumber'] == patientData['phoneNumber']  && patient['timestamp'].toDate().isBefore(patientData['timestamp'].toDate())).toList();

    if (previousRegistrations.isNotEmpty) {
      // widgets.add(
      //   // Text(
      //   //   'Previous Registrations:',
      //   //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      //   // ),
      // );

      // Display details of each previous registration
      previousRegistrations.forEach((registration) {
        widgets.addAll([
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date and Time: ${formattedTimestamp(registration)}'),
                Text('Disease: ${registration['disease'] ?? 'Unknown'}'),
                // Add more details as needed
              ],
            ),
          ),
        ]);
      });
    }

    return widgets;
  }


}

Future<void> _sendMessages(String phoneNumber) async {
  TwilioFlutter twilioFlutter = TwilioFlutter(
    accountSid: 'ACea352cee8e8c865a91cb95d394c0f079',
    authToken: '84d33cb9710ebb8483ea3d7b56961b74',
    twilioNumber: '+12675364671',
  );

  try {
    await twilioFlutter.sendSMS(
      toNumber: phoneNumber,
      messageBody: 'please be ready',
    );
    print('Message sent successfully');
  } catch (e) {
    print('Error sending message: $e');
  }
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
            Text('Patient ID: ${appointmentData['pid']?.toString() ??
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