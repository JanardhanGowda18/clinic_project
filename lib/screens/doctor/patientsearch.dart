import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientSearchDelegate extends SearchDelegate<String> {
  List<Map<String, dynamic>> patientDataList;

  PatientSearchDelegate(this.patientDataList, {required void Function(String query) onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    List<Map<String, dynamic>> searchResults = patientDataList
        .where((patient) =>
    patient['name']
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        patient['pid']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    if (searchResults.isEmpty) {
      return Center(
        child: Text('No results found.'),
      );
    }

    return ListView(
      children: [
        Center(
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.blue,
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            columnSpacing: 100.0,
            // dataRowMinHeight: 40.0,
            dividerThickness: 1.0,
            border: TableBorder.all(color: Colors.black),
            columns: [
              DataColumn(
                label: Container(
                  alignment: Alignment.center,
                  child: Text('Patient ID'),
                  padding: EdgeInsets.only(bottom: 5.0),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Container(
                  alignment: Alignment.center,
                  child: Text('Name'),
                  padding: EdgeInsets.only(bottom: 5.0),
                ),
              ),
              DataColumn(
                label: Container(
                  child: Center(
                    child: Text('Age'),
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  child: Center(
                    child: Text('Disease'),
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  child: Center(
                    child: Text('Gender'),
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  child: Center(
                    child: Text('Phone Number'),
                  ),
                ),
              ),
              DataColumn(
                label: Container(
                  child: Center(
                    child: Text('Time and Date'),
                  ),
                ),
              ),
            ],
            rows: searchResults.map((patientData) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      alignment: Alignment.center,
                      child: Text(patientData['pid']?.toString() ?? ''),
                    ),
                  ),
                  DataCell(
                    Container(
                      alignment: Alignment.center,
                      child: Text(patientData['name'] ?? ''),
                    ),
                  ),
                  DataCell(
                    Text(patientData['age']?.toString() ?? ''),
                  ),
                  DataCell(
                    GestureDetector(
                      onTap: () {
                        // Handle tapping on disease cell
                      },
                      child: Text(
                        patientData['disease'] ?? '',
                        style: TextStyle(),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(patientData['gender'] ?? ''),
                  ),
                  DataCell(
                    Text('+91 ${patientData['phoneNumber'] ?? ''}'),
                  ),

                  DataCell(
                    Text(formattedTimestamp(patientData)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  void onSubmitted(String value) {
    // Handle the submission of the search query
    // You can choose to close the search or perform any other action
  }

  String formattedTimestamp(Map<String, dynamic> patientData) {
    Timestamp? timestamp = patientData['timestamp'] as Timestamp?;
    DateTime? dateTime = timestamp?.toDate();
    return dateTime != null
        ? DateFormat.yMd().add_Hm().format(dateTime)
        : 'N/A';
  }
}