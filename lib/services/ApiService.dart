// File: services/ApiService.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String baseUrl =
      'https://csg71h0em2.execute-api.ap-south-1.amazonaws.com/Prod';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getIdToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<void> addToMatchQueue(Map<String, dynamic> userData) async {
    String? idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/addToMatchQueue'),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*', // Allow all origins
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add to match queue: ${response.body}');
    }
  }

  Future<void> removeFromMatchQueue() async {
    String? idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/removeFromMatchQueue'),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*', // Allow all origins
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove from match queue: ${response.body}');
    }
  }

  Stream<DocumentSnapshot> listenForMatches(String userId) {
    return _firestore.collection('userChats').doc(userId).snapshots();
  }

  Future<void> sendNotification({
    required String recipientUserId,
    required String chatId,
    required String type,
    String? body,
  }) async {
    String? idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    // payload should match this interface
    // interface NotificationData {
    //     recipientUserId: string;
    //     body?: string;
    //     type: "text" | "photo" | "video" | "audio";
    //     senderId: string;
    //     chatId: string;
    // }
    final notificationData = {
      'recipientUserId': recipientUserId,
      'type': type,
      'senderId': _auth.currentUser!.uid,
      'chatId': chatId,
      if (body != null) 'body': body,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/sendNewMessageNotification'),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(notificationData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }
}