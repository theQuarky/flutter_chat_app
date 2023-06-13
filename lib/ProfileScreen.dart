import 'package:chat_app/AuthScreen.dart';
import 'package:chat_app/services/userService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

enum Gender { male, female }

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _newUser = true;
  File? _selectedImage;

  Gender _gender = Gender.male;

  void getProfile() async {
    User? user = await FirebaseAuth.instance.currentUser;
    try {
      UserModal? data = await getUserDataByUID(user?.uid);
      if (data != null) {
        DateTime dateTime = DateTime.parse(data.dob ?? '');

        String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
        setState(() {
          _gender = data.gender == 'male' ? Gender.male : Gender.female;
          _displayNameController.text = data.displayName!;
          _imageController.text = data.imageUrl ?? '';
          _dobController.text = formattedDate;
          _newUser = false;
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    getProfile();
    super.initState();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _imageController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final reference = FirebaseStorage.instance.ref().child(fileName);
      await reference.putFile(imageFile);
      final imageUrl = await reference.getDownloadURL();
      _imageController.text = imageUrl;
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _saveProfile() async {
    // if (_formKey.currentState!.validate()) {
    // File imageFile = File(_imageController.text);
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
    }

    final String displayName = _displayNameController.text.trim();
    final String gender = _gender.name;
    final String dob = _dobController.text.trim();

    DateTime currentDate = DateTime.now();
    DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(dob);
    Duration difference = currentDate.difference(selectedDate);
    int age = difference.inDays ~/ 365;

    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You must be 18 years old to use this app')));
      return;
    }

    if (!_newUser) {
      UserModal user = UserModal(
          uid: FirebaseAuth.instance.currentUser?.uid ?? "",
          displayName: displayName,
          gender: gender,
          dob: dob,
          imageUrl: imageUrl);
      UserModal? data = await updateUserData(user);

      if (data != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile Updated!')));
        getProfile();
      }
    } else {
      UserModal user = UserModal(
          uid: FirebaseAuth.instance.currentUser?.uid ?? "",
          displayName: displayName,
          gender: gender,
          dob: dob,
          imageUrl: imageUrl);
      bool data = await insertUserData(user);
      if (data) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile Saved!')));
        getProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error Occur while saving your profile')));
      }
    }
    // }
  }

  pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _selectedImage = File(image.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Profile'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AuthScreen()));
            },
            icon: Icon(Icons.logout),
          )
        ],
        leading: null,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          SizedBox(height: 16),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: ClipOval(
                child:
                    _imageController.text.isNotEmpty || _selectedImage != null
                        ? (_selectedImage == null
                            ? Image(
                                image: NetworkImage(_imageController.text),
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ))
                        : ElevatedButton(
                            onPressed: pickImage,
                            child: Icon(Icons.camera_alt),
                          ),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter a display name.';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _dobController,
            decoration: InputDecoration(
              labelText: "Date Of Birth",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            onTap: () async {
              if (!_newUser) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Can not change Date of birth')));
                return;
              }

              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(pickedDate);
                setState(() {
                  _dobController.text = formattedDate;
                });
              } else {
                print("Date is not selected");
              }
            },
          ),
          SizedBox(height: 16),
          ListTile(
            title: Text(
              'Male',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            leading: Icon(Icons.male, color: Colors.blue),
            trailing: Radio<Gender>(
              groupValue: _gender,
              value: Gender.male,
              onChanged: (value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
          ),
          ListTile(
            title: Text(
              'Female',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            leading: Icon(Icons.female, color: Colors.blue),
            trailing: Radio<Gender>(
              groupValue: _gender,
              value: Gender.female,
              onChanged: (value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            child: Text('Save', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
