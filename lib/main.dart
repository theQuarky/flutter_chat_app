import 'dart:convert';

import 'package:chat_app/ProfileScreen.dart';
import 'package:chat_app/SearchScreen.dart';
import 'package:chat_app/TempChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'AuthScreen.dart';
import 'HomeScreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            final isLoggedIn = snapshot.hasData;
            final initialRoute = isLoggedIn ? '/home' : '/auth';

            return Navigator(
              initialRoute: initialRoute,
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    switch (settings.name) {
                      case '/home':
                        return const HomeScreen(newUser: false);
                      case '/auth':
                        return const AuthScreen();
                      case '/search':
                        return const SearchScreen();
                      case '/profile':
                        return const ProfileEditScreen();
                      case '/tempChat':
                        return const TempChatScreen();
                      default:
                        return const HomeScreen(newUser: false);
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
