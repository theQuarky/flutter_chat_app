import 'package:chat_app/ChatScreen.dart';
import 'package:chat_app/ProfileScreen.dart';
import 'package:chat_app/SearchScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'AuthScreen.dart';
import 'HomeScreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

// Future<String> getUrl() async {
//   return await FirebaseStorage.instance.ref().getDownloadURL();
// }

// class TestNetworkImage extends StatefulWidget {
//   TestNetworkImage({super.key});

//   @override
//   State<TestNetworkImage> createState() => _TestNetworkImageState();
// }

// class _TestNetworkImageState extends State<TestNetworkImage> {
//   late String url;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: Image.network(
//       'https://firebasestorage.googleapis.com/v0/b/flutter-c91c8.appspot.com/o/1687252429029?alt=media&token=eed6d796-38d4-4a28-a7d0-7eb27ffac6fb',
//       fit: BoxFit.cover,
//       width: 200,
//       height: 200,
//     ));
//   }
// }

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
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
            return HomeWrapper(
              initialRoute: initialRoute,
              currentUser: snapshot.data,
            );
          }
        },
      ),
    );
  }
}

class HomeWrapper extends StatelessWidget {
  final String initialRoute;
  final User? currentUser;

  const HomeWrapper({
    Key? key,
    required this.initialRoute,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _getRouteIndex(initialRoute),
      children: <Widget>[
        const HomeScreen(),
        const AuthScreen(),
        const SearchScreen(),
        const ProfileEditScreen(),
        if (initialRoute == '/chat')
          ChatScreen(partnerId: getPartnerIdFromRoute(context)),
      ],
    );
  }

  int _getRouteIndex(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/auth':
        return 1;
      case '/search':
        return 2;
      case '/profile':
        return 3;
      case '/chat':
        return 5;
      default:
        return 0;
    }
  }

  String getPartnerIdFromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String) {
      return arguments;
    }
    return '';
  }
}
