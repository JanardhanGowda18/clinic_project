import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

class PatientForm extends StatefulWidget {
  @override
  _PatientFormState createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cashPhonePayController = TextEditingController();
  final TextEditingController manualDiseaseController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController(); // Add prescription controller

  String _selectedDisease = 'Select Dis';
  String _selectedGender = 'Select Gender';
  String _selectedPaymentMethod = 'Cash';

  List<String> _diseases = ['Select Dis', 'Cold', 'Fever', 'Stomach Pain', 'Covid', 'Others'];
  List<String> _genders = ['Select Gender', 'Male', 'Female', 'Others'];

  int _patientCount = 0; // Global variable to keep track of patient count

  @override
  void initState() {
    super.initState();
    _getLatestPatientId();
  }

  Future<void> _getLatestPatientId() async {
    var latestPatient = await FirebaseService.getPatientsCollection().orderBy('pid', descending: true).limit(1).get();
    if (latestPatient.docs.isNotEmpty) {
      _patientCount = latestPatient.docs.first['pid'];
    }
  }

  void _saveFormData() async {
    String name = _nameController.text.trim();
    String age = _ageController.text.trim();
    String phoneNumber = "+91" + _phoneNumberController.text.trim();
    String gmail = _gmailController.text.trim();
    String address = _addressController.text.trim();
    String enteredDisease = manualDiseaseController.text.trim();
    String cashPhonePay = _cashPhonePayController.text.trim();

    // Include prescription with initial value of null
    if (_selectedDisease == 'Others' && enteredDisease.isNotEmpty) {
      setState(() {
        _selectedDisease = enteredDisease;
      });
    }

    if (name.isNotEmpty && age.isNotEmpty && phoneNumber.isNotEmpty && address.isNotEmpty) {
      try {
        int? parsedAge = int.tryParse(age);

        if (parsedAge != null) {
          var documentReference = await FirebaseService.getPatientsCollection().add({
            'pid': ++_patientCount,
            'name': name,
            'age': parsedAge,
            'phoneNumber': phoneNumber,
            'gmail': gmail,
            'address': address,
            'disease': _selectedDisease,
            'gender': _selectedGender,
            'cashPhonePay': cashPhonePay,
            'prescription': null, // Initial value of prescription
            'timestamp': DateTime.now(),
          });

          _nameController.clear();
          _ageController.clear();
          _phoneNumberController.clear();
          _gmailController.clear();
          _addressController.clear();
          manualDiseaseController.clear();
          _cashPhonePayController.clear();
          _prescriptionController.clear();

          setState(() {
            _selectedDisease = 'Select Dis';
            _selectedGender = 'Select Gender';
          });

          _showSuccessDialog();
        } else {
          _showErrorDialog('Invalid age input');
        }
      } catch (e) {
        print('Error saving data: $e');
        _showErrorDialog('Failed to save data. Please try again.');
      }
    } else {
      _showErrorDialog('All fields are required');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Submission successful!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Payment Method'),
          content: Column(
            children: [
              ListTile(
                title: Text('Phone Pay'),
                onTap: () {
                  _selectPaymentMethod('Phone Pay');
                },
              ),
              ListTile(
                title: Text('Google Pay'),
                onTap: () {
                  _selectPaymentMethod('Google Pay');
                },
              ),
              // Add more payment methods as needed
            ],
          ),
        );
      },
    );
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Form'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: CircleAvatar(
                backgroundImage: AssetImage('images/1.jpg'),
                radius: 100.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Patient Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _phoneNumberController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixText: '+91 ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(13),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _gmailController,
                        decoration: InputDecoration(
                          labelText: 'Gmail',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDisease,
                        onChanged: (value) {
                          setState(() {
                            _selectedDisease = value!;
                          });
                        },
                        items: _diseases.map((disease) {
                          return DropdownMenuItem<String>(
                            value: disease,
                            child: Text(disease),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Disease',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: _selectedDisease == 'Others',
                        child: SizedBox(height: 16),
                      ),
                      Visibility(
                        visible: _selectedDisease == 'Others',
                        child: TextFormField(
                          controller: manualDiseaseController,
                          decoration: InputDecoration(
                            labelText: 'Enter Disease',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                        items: _genders.map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Payment Method:'),
                          Radio(
                            value: 'UPI',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value.toString();
                                if (_selectedPaymentMethod == 'UPI') {
                                  _showPaymentMethodsDialog();
                                }
                              });
                            },
                          ),
                          Text('UPI'),
                          Radio(
                            value: 'Cash',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value.toString();
                              });
                            },
                          ),
                          Text('Cash'),
                        ],
                      ),
                      Visibility(
                        visible: false, // Initially hide the prescription field
                        child: TextFormField(
                          controller: _prescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Prescription',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveFormData,
                          child: Text('Submit',style: TextStyle(color:Colors.white),),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
