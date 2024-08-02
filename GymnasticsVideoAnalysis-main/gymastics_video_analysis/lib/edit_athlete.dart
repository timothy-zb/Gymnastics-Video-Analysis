import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAthleteScreen extends StatefulWidget {
  final String docId;
  final String athleteName;
  final int age;
  final double height;
  final double weight;
  final String gender;

  EditAthleteScreen({
    required this.docId,
    required this.athleteName,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
  });

  @override
  _EditAthleteScreenState createState() => _EditAthleteScreenState();
}

class _EditAthleteScreenState extends State<EditAthleteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _athleteName;
  late int _age;
  late double _height;
  late double _weight;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _athleteName = widget.athleteName;
    _age = widget.age;
    _height = widget.height;
    _weight = widget.weight;
    _gender = widget.gender;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Update the athlete details in Firestore
      FirebaseFirestore.instance
          .collection('athletes')
          .doc(widget.docId)
          .update({
        'athleteName': _athleteName,
        'age': _age,
        'height': _height,
        'weight': _weight,
        'gender': _gender,
      }).then((_) {
        Navigator.pop(context);
      }).catchError((error) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to update athlete details.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
    }
  }

  String? _validateAge(String? value) {
    if (value!.isEmpty) {
      return 'Please enter the age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 18 || age > 100) {
      return 'Age must be between 18 and 100';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value!.isEmpty) {
      return 'Please enter the height';
    }
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid height';
    }
    if (height <= 0.0 || height > 300.0) {
      return 'Height must be between 0 and 300';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value!.isEmpty) {
      return 'Please enter the weight';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    if (weight <= 0.0 || weight > 1000.0) {
      return 'Weight must be between 0 and 1000';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48),
              Text(
                'Edit Athlete',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _athleteName,
                      decoration: InputDecoration(
                        labelText: 'Athlete Name',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the athlete name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _athleteName = value!;
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _age.toString(),
                      decoration: InputDecoration(
                        labelText: 'Age',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      validator: _validateAge,
                      onSaved: (value) {
                        _age = int.parse(value!);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _height.toString(),
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      validator: _validateHeight,
                      onSaved: (value) {
                        _height = double.parse(value!);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _weight.toString(),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      validator: _validateWeight,
                      onSaved: (value) {
                        _weight = double.parse(value!);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the gender';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _gender = value!;
                      },
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                        onPrimary: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
