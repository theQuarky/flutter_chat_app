import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io';

// Import for web
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

class ProfileEditScreen extends StatefulWidget {
  final bool isNewUser;

  const ProfileEditScreen({Key? key, this.isNewUser = false}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  dynamic _imageFile;
  String? _imageUrl;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !widget.isNewUser) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        setState(() {
          _nameController.text = userData['displayName'] ?? '';
          _bioController.text = userData['bio'] ?? '';
          _birthDate = userData['birthDate']?.toDate();
          _gender = userData['gender'];
          _imageUrl = userData['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        var f = await image.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = null;
        });
      }
    } else {
      final ImagePicker _picker = ImagePicker();
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = _imageUrl;
        if (_webImage != null || _imageFile != null) {
          final ref =
              FirebaseStorage.instance.ref().child('user_profiles/${user.uid}');
          if (kIsWeb) {
            await ref.putData(_webImage!);
          } else {
            await ref.putFile(_imageFile);
          }
          imageUrl = await ref.getDownloadURL();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameController.text,
          'bio': _bioController.text,
          'birthDate': _birthDate,
          'gender': _gender,
          'profileImageUrl': imageUrl,
          'profileCompleted': true,
        }, SetOptions(merge: true));

        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewUser ? 'Create Profile' : 'Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _getImageProvider(),
                    child: _imageFile == null &&
                            _webImage == null &&
                            _imageUrl == null
                        ? Icon(Icons.add_a_photo,
                            size: 50, color: Colors.grey[600])
                        : null,
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text(_birthDate == null
                      ? 'Select Birth Date'
                      : 'Birth Date: ${_birthDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != _birthDate) {
                      setState(() {
                        _birthDate = picked;
                      });
                    }
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _gender = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (_webImage != null) {
      return MemoryImage(_webImage!);
    } else if (_imageFile != null) {
      return FileImage(_imageFile);
    } else if (_imageUrl != null) {
      return NetworkImage(_imageUrl!);
    }
    return null;
  }
}
