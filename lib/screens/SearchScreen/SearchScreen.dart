import 'dart:async';
import 'package:chat_app/screens/SearchScreen/TempChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chat_app/services/MatchService.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchService _matchService = MatchService();
  Timer? _matchCheckTimer;
  bool _isSearching = false;
  String? _userId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _setupAnimation();

    // Delay the location request slightly
    Future.delayed(Duration(milliseconds: 500), () {
      _getCurrentLocation();
    });
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<bool> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')),
      );
      return false;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return false;
    }
  }

  void startSearch() async {
    if (_userId == null) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Prepare queue data
      Map<String, dynamic> queueData = {
        'userId': _userId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_currentPosition != null) {
        queueData['latitude'] = _currentPosition!.latitude;
        queueData['longitude'] = _currentPosition!.longitude;
      }

      // Add user to match queue
      await _firestore.collection('matchQueue').add(queueData);
      print("Successfully added to matchQueue with data: $queueData");

      // Start periodic match checking
      _matchCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
        if (_isSearching) {
          _findMatch();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print("Error during search process: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting search: $e')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _findMatch() async {
    if (_userId == null) return;

    final matchedUserId = await _matchService.findMatch(_userId!);
    if (matchedUserId != null) {
      _onMatchFound(matchedUserId);
    } else {
      print('No match found at this time.');
    }
  }

  void _onMatchFound(String matchedUserId) {
    stopSearch();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TempChatScreen(matchedUserId: matchedUserId),
    ));
  }

  void stopSearch() {
    setState(() {
      _isSearching = false;
    });
    _matchCheckTimer?.cancel();
    if (_userId != null) {
      _firestore
          .collection('matchQueue')
          .where('userId', isEqualTo: _userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _matchCheckTimer?.cancel();
    stopSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSearching)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (BuildContext context, Widget? child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            if (!_isSearching)
              ElevatedButton(
                onPressed: startSearch,
                child: const Text('Start Search'),
              )
            else
              ElevatedButton(
                onPressed: stopSearch,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Stop Search'),
              ),
          ],
        ),
      ),
    );
  }
}
