import 'package:chat_app/ProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<UserModal?> getUserDataByUID(String? uid) async {
  final apiUrl =
      'http://127.0.0.1:3000/v1/users/get?uid=$uid'; // Replace with your API endpoint

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(response.body)['user'];

      return UserModal.fromJson(jsonData);
    } else {
      // Error occurred while getting user data
      print('Failed to get user data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    // Error occurred while making the HTTP request
    print('GET Error: $e');
  }

  return null;
}

Future<bool> insertUserData(UserModal user) async {
  final apiUrl =
      'http://127.0.0.1:3000/v1/users/insert'; // Replace with your API endpoint

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      // User data successfully inserted
      print('User data inserted');
      return true;
    } else {
      // Error occurred while inserting user data
      print('Failed to insert user data. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    }
  } catch (e) {
    // Error occurred while making the HTTP request
    print('Error: $e');
    return false;
  }
}

Future<UserModal?> updateUserData(UserModal user) async {
  final apiUrl =
      'http://127.0.0.1:3000/v1/users/update'; // Replace with your API endpoint

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      // User data successfully inserted
      return UserModal.fromJson(jsonDecode(response.body)['user']);
    } else {
      // Error occurred while inserting user data
      print('Failed to insert user data. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    // Error occurred while making the HTTP request
    print('Error: $e');
  }
  return null;
}

class UserModal {
  String? uid = null;
  String? displayName = '';
  String? gender = 'male';
  String? dob = '';
  String? deviceToken;
  List<dynamic> friends = [];
  bool isActive = true;
  String? imageUrl;
  bool isDeleted = false;

  UserModal({
    this.uid,
    this.displayName,
    this.gender,
    this.dob,
    this.deviceToken,
    this.friends = const [],
    this.isActive = true,
    this.imageUrl,
    this.isDeleted = false,
  });

  UserModal.fromJson(json) {
    uid = json['uid'];
    displayName = json['displayName'];
    gender = json['gender'];
    dob = json['dob'];
    deviceToken = json['deviceToken'] ?? '';
    friends = json['friends'] ?? [];
    isActive = json['isActive'] ?? false;
    imageUrl = json['imageUrl'] ?? '';
    isDeleted = json['isDeleted'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'displayName': displayName,
      'gender': gender,
      'dob': dob,
      'deviceToken': deviceToken,
      'friends': friends,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'isDeleted': isDeleted,
    };
    return data;
  }

  // Implement any additional methods or logic related to the UserModal class
}
