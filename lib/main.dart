import 'package:chat_app/AuthScreen.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/screens/Home/HomeScreen.dart';
import 'package:chat_app/screens/Profile/ProfileEditScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_app/services/NotificationService.dart';
import 'package:chat_app/screens/Chat/ChatScreen.dart';
// Import other necessary files

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    NotificationService.onNotificationTap = _handleNotificationTap;
  }

  void _handleNotificationTap(String chatId, String friendId) {
    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'chatId': chatId,
        'friendId': friendId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/auth': (context) => AuthScreen(),
        '/profile': (context) => ProfileEditScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PermanentChatScreen(
            chatId: args['chatId'],
            friendId: args['friendId'],
          );
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        } else if (snapshot.hasData) {
          // Check if there's an initial route to navigate to
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final initialRoute = ModalRoute.of(context)?.settings.name;
            if (initialRoute != null && initialRoute != '/') {
              Navigator.of(context).pushReplacementNamed(initialRoute);
            }
          });
          return ProfileCheck(userId: snapshot.data!.uid);
        } else {
          return AuthScreen();
        }
      },
    );
  }
}

class ProfileCheck extends StatelessWidget {
  final String userId;

  ProfileCheck({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          // Document doesn't exist, so profile is not completed
          return ProfileEditScreen();
        }

        final userData = snapshot.data!.data();
        if (userData == null || userData['profileCompleted'] != true) {
          return ProfileEditScreen();
        }
        return HomeScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
