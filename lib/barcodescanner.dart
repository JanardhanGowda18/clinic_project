// // Import the qr_scanner.dart file
// import 'package:health_care/screens/qr_scanner.dart';
//
//
// // ...
//
// Future<void> _scanCode() async {
//   String? result = await QRScanner.scanCode();
//   if (result != null) {
//     // Handle the scanned data, for example, open the form with the scanned data
//     _handleScannedData(result);
//   }
// }
//
// void _handleScannedData(String data) {
//   // Use the scanned data to open the form or perform any other actions
//   print("Scanned code: $data");
//
//   // For simplicity, let's assume the scanned code is the patient's name
//   _nameController.text = data;
//
//   // Open the appointment form or handle the data as needed
// }
