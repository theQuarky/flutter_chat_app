import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:http/http.dart' as http;

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

  Gender _gender = Gender.male;

  void getProfile() async {
    User? user = await FirebaseAuth.instance.currentUser;
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user?.uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    setState(() {
      _gender = data['gender'] == 'male' ? Gender.male : Gender.female;
      _displayNameController.text = data['displayName'];
      _imageController.text = data['image'];
      _dobController.text = data['dob'];
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

  Future<String> uploadImageFromBlobUrl(String imageUrl) async {
    // Fetch the image data from the blob URL
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;

    // Generate a unique file name
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('profilePictures/$uid/picture.jpg');
    UploadTask uploadTask = storageReference.putData(bytes);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    setState(() {
      _imageController.text = downloadUrl;
    });
    return downloadUrl;
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // File imageFile = File(_imageController.text);
      String imageUrl = await uploadImageFromBlobUrl(_imageController.text);
      final String displayName = _displayNameController.text.trim();
      final String image = _imageController.text.trim();
      final String gender = _gender.name;
      final String dob = _dobController.text.trim();
      CollectionReference usersCollection = _firestore.collection('users');

// Create a new document with the user's UID as the document ID
      DocumentReference newUserRef =
          usersCollection.doc(FirebaseAuth.instance.currentUser?.uid);

// Set the data for the document
      newUserRef.set({
        'displayName': displayName,
        'image': imageUrl,
        'gender': gender,
        'dob': dob,
      }).then((_) {
        // Document successfully added to Firestore
        print('User data saved to Firestore');
        getProfile();
      }).catchError((error) {
        // Error occurred while saving document to Firestore
        print('Failed to save user data: $error');
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageController.text = pickedImage.path;
      });
    }
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
                        child: _imageController.text.isNotEmpty
                            ? Image.network(
                                _imageController.text,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  print(exception);
                                  return const Text('Failed to load image');
                                },
                              )
                            : ElevatedButton(
                                onPressed: _pickImage,
                                child: const Icon(Icons.camera_alt),
                              ),
                      ),
                    ),
                    if (_imageController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          setState(() {
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
                    onPressed: FirebaseAuth.instance.signOut,
                    child: const Text('Logout'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
