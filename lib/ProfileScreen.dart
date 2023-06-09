import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Gender _gender = Gender.male;

  void getProfile() async {
    User? user = await FirebaseAuth.instance.currentUser;
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user?.uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    setState(() {
      _gender = data['gender'] == 'male' ? Gender.male : Gender.female;
      _displayNameController.text = data['displayName'] ?? '';
      _imageController.text = data['image'] ?? '';
      _dobController.text = data['dob'] ?? '';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
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
    if (_formKey.currentState!.validate()) {
      // File imageFile = File(_imageController.text);
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await uploadImage(_selectedImage!);
      }

      final String displayName = _displayNameController.text.trim();
      final String gender = _gender.name;
      final String dob = _dobController.text.trim();
      CollectionReference usersCollection = _firestore.collection('users');

// Create a new document with the user's UID as the document ID
      DocumentReference newUserRef =
          usersCollection.doc(FirebaseAuth.instance.currentUser?.uid);

      DocumentSnapshot f = await newUserRef.get();
      dynamic data;

      if (imageUrl != null) {
        data = {
          'displayName': displayName,
          'image': imageUrl,
          'gender': gender,
          'dob': dob,
        };
      } else {
        data = {
          'displayName': displayName,
          'gender': gender,
          'dob': dob,
        };
      }
      if (f.data() != null) {
        newUserRef.update(data).then((_) {
          // Document successfully added to Firestore
          print('User data saved to Firestore');
          getProfile();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile Updated!')));
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error Occur while saving your profile')));
          print('Failed to save user data: $error');
        });
      } else {
        newUserRef.set(data).then((_) {
          print("User saved!");
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile Saved!')));
          Navigator.pushNamed(context, '/home');
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error Occur while saving your profile')));
          print("Failed to save user: $error");
        });
      }
    }
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
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: Container(
                        width: 100, // Adjust the size of the circle as needed
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: _imageController.text.isNotEmpty ||
                                  _selectedImage != null
                              ? (_selectedImage == null
                                  ? Image(
                                      image:
                                          NetworkImage(_imageController.text),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ))
                              : ElevatedButton(
                                  onPressed: pickImage,
                                  child: const Icon(Icons.camera_alt),
                                ),
                        ),
                      ),
                    ),
                    if (_imageController.text.isNotEmpty ||
                        _selectedImage != null)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _imageController.text = '';
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a display name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today),
                    labelText: "Date Of Birth",
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
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
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Male'),
                  leading: const Icon(Icons.male),
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
                  title: const Text('Female'),
                  leading: const Icon(Icons.female),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamed(context, '/auth');
                    },
                    child: const Text('Logout'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
