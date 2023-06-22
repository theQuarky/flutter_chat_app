import 'dart:html' as html;
import 'dart:typed_data';

import 'package:chat_app/AuthScreen.dart';
import 'package:chat_app/MainScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
// import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:image_picker/image_picker.dart';

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
  String extension = '';
  bool isNewUser = true;
  String url = '';
  // File? _selectedImage;
  html.Blob? _selectedImage;

  Gender _gender = Gender.male;

  void getProfile() async {
    User? user = await FirebaseAuth.instance.currentUser;
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user?.uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data.isNotEmpty) {
      setState(() {
        isNewUser = false;
        _gender = data['gender'] == 'male' ? Gender.male : Gender.female;
        _displayNameController.text = data['displayName'] ?? '';
        _imageController.text = data['image'] ?? '';
        url = data['image'] ?? '';
        _dobController.text = data['dob'] ?? '';
      });
    }
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

  Future<String>? uploadImage(dynamic imageFile) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      final Uint8List imageData = response.bodyBytes;

      // Generate a unique filename for the image (optional)
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a reference to the Firebase Storage location
      firebase_storage.Reference storageReference =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);

      // Upload the image data to Firebase Storage
      firebase_storage.UploadTask uploadTask =
          storageReference.putData(imageData);

      // Get the download URL of the uploaded image
      firebase_storage.TaskSnapshot storageSnapshot =
          await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      // Use the download URL as needed (e.g., save it to a document in Firestore)
      print('Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print("ERROR: $e");
      throw e;
    }
  }

  // this one is for android
  // Future<String?> uploadImage(File imageFile) async {
  //   try {
  //     final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //     final reference = FirebaseStorage.instance.ref().child(fileName);
  //     await reference.putFile(imageFile);
  //     final imageUrl = await reference.getDownloadURL();
  //     _imageController.text = imageUrl;
  //     return imageUrl;
  //   } catch (e) {
  //     print('Error uploading image: $e');
  //     return null;
  //   }
  // }

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
          Navigator.push(
              context, MaterialPageRoute(builder: (builder) => MainScreen()));
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
    final bytes = await image.readAsBytes();
    setState(() {
      extension = image.mimeType!.split('/').last;
      url = image.path;
      _selectedImage = html.Blob(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    print(url);
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
                        child: _selectedImage != null || url != ''
                            ? CircleAvatar(
                                backgroundImage: Image.network(url).image)
                            : ClipOval(
                                child: ElevatedButton(
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
                            url = '';
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
                    onPressed: () => FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .update({'deviceToken': ''}).then((value) {
                          FirebaseAuth.instance.signOut();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (builder) => AuthScreen()));
                        }).catchError((onError) {
                          FirebaseAuth.instance.signOut();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (builder) => AuthScreen()));
                        }),
                    child: const Text('Logout'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
