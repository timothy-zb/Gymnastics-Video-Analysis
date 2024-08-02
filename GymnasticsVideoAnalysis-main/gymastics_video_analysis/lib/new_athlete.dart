import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/home.dart';

class NewAthleteScreen extends StatefulWidget {
  @override
  _NewAthleteScreenState createState() => _NewAthleteScreenState();
}

class _NewAthleteScreenState extends State<NewAthleteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _athleteName = '';
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
  String _gender = '';

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final collection = FirebaseFirestore.instance.collection('athletes');
        final docRef = await collection.add({
          'athleteName': _athleteName,
          'age': _age,
          'height': _height,
          'weight': _weight,
          'gender': _gender,
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Athlete details saved successfully.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        print(e.toString());

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to save athlete details. Error: $e'),
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
      }
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
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'New Athlete',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Athlete Name',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                validator: _validateWeight,
                onSaved: (value) {
                  _weight = double.parse(value!);
                },
              ),
              SizedBox(height: 20.0),
              Text(
                'Gender',
                style: TextStyle(color: Colors.black),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text(
                    'Male',
                    style: TextStyle(color: Colors.black),
                  ),
                  Radio<String>(
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text(
                    'Female',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text('Submit'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  onPrimary: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
