import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:health_care/screens/doctor/todays/TodaysAppointment.dart';
import 'package:path_provider/path_provider.dart';  // Import path_provider package
import 'package:health_care/screens/doctor/DoctorDashboard.dart';
import 'package:health_care/screens/doctor/doctor_login_screen.dart';
import 'package:health_care/screens/patient.dart';
import 'package:health_care/services/firebase_service.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Patient Form',
        home: DashboardScreen(),
      ),
    );
  }
}
