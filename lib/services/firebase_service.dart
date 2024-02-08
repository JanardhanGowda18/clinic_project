import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import '../firebase_options.dart';

class FirebaseService {
  static int _pidCounter = 0;

  static Future<void> initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Fetch the latest pid from the database on initialization
    await _fetchLatestPid();
  }

  static Future<void> _fetchLatestPid() async {
    try {
      QuerySnapshot querySnapshot = await getPatientsCollection()
          .orderBy('pid', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _pidCounter = querySnapshot.docs.first.get('pid') + 1;
      } else {
        // If there's no existing pid, start from 1
        _pidCounter = 1;
      }
    } catch (e) {
      print('Error fetching latest pid: $e');
    }
  }

  static CollectionReference getPatientsCollection() {
    return FirebaseFirestore.instance.collection('patients');
  }

  static Future<void> saveFormData(Map<String, dynamic> data) async {
    try {
      // Use the _pidCounter as the pid
      int newPid = _pidCounter++;

      // Add the new pid to the data
      data['pid'] = newPid;

      // Save the form data to Firestore
      await getPatientsCollection().add(data);
    } catch (e) {
      print('Error saving data: $e');
      rethrow; // Rethrow the error to be caught by the caller
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPatientData() async {
    try {
      QuerySnapshot querySnapshot = await getPatientsCollection().get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching patient data: $e');
      throw e; // Rethrow the error to be caught by the caller
    }
  }

  static Future<void> deleteAppointment(int? pid) async {
    try {
      if (pid != null) {
        // Find the document with the specified pid and delete it
        await getPatientsCollection().where('pid', isEqualTo: pid).get().then(
              (QuerySnapshot querySnapshot) {
            querySnapshot.docs.forEach(
                  (doc) async {
                await doc.reference.delete();
              },
            );
          },
        );
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e; // Rethrow the error to be caught by the caller
    }
  }

  static Future<List<String>> fetchDiseases() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('diseases').get();

      List<String> diseases = querySnapshot.docs
          .map((doc) => doc.get('name') as String)
          .toList();

      return diseases;
    } catch (e) {
      print('Error fetching diseases: $e');
      throw e; // Rethrow the error to be caught by the caller
    }
  }
  static Future<void> updatePrescription(int pid, String prescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(pid.toString())
          .update({'prescription': prescription});
      print('Prescription updated successfully');
    } catch (e) {
      print('Error updating prescription: $e');
      // Handle error as needed
      throw e; // Re-throwing the error to propagate it
    }
  }
}