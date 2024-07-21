import 'package:chat_app/components/search_button.dart';
import 'package:chat_app/screens/SearchScreen/MatchListener.dart';
import 'package:chat_app/screens/SearchScreen/SearchAnimation.dart';
import 'package:chat_app/services/LocationService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chat_app/services/ApiService.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final MatchListener _matchListener = MatchListener();
  bool _isSearching = false;
  String? _userId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    _currentPosition = await _locationService.getCurrentLocation(context);
  }

  void startSearch() async {
    if (_userId == null) return;

    setState(() {
      _isSearching = true;
    });

    try {
      Map<String, dynamic> requestBody = {
        'userId': _userId,
      };

      if (_currentPosition != null) {
        requestBody['location'] = {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        };
      }

      await _apiService.addToMatchQueue(requestBody);
      _matchListener.listenForNewMatches(context, stopAnimation);
    } catch (e) {
      print("Error during search process: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting search: $e')),
      );
      stopAnimation();
    }
  }

  void stopAnimation() {
    setState(() {
      _isSearching = false;
    });
  }

  void stopSearch() async {
    stopAnimation();
    try {
      await _apiService.removeFromMatchQueue();
    } catch (e) {
      print('Error stopping search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSearching) SearchAnimation(),
            const SizedBox(height: 20),
            SearchButton(
              isSearching: _isSearching,
              onStartSearch: startSearch,
              onStopSearch: stopSearch,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matchListener.dispose();
    super.dispose();
  }
}
