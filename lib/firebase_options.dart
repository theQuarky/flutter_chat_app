// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCUoIB-Ng-im33Ii9B9O49MjGkSFJsHoJw',
    appId: '1:327775764664:web:94b48eae272a9da559344d',
    messagingSenderId: '327775764664',
    projectId: 'flutter-c91c8',
    authDomain: 'flutter-c91c8.firebaseapp.com',
    storageBucket: 'flutter-c91c8.appspot.com',
    measurementId: 'G-V327W8PRSZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDf5YW44ebirOb4CQU2TOkGA_cFcq2LEE0',
    appId: '1:327775764664:android:467af3283cb965d059344d',
    messagingSenderId: '327775764664',
    projectId: 'flutter-c91c8',
    storageBucket: 'flutter-c91c8.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCooTlr8MPr8ssgBct0YRuyW_v2ogVSEKE',
    appId: '1:327775764664:ios:dbea90814185020459344d',
    messagingSenderId: '327775764664',
    projectId: 'flutter-c91c8',
    storageBucket: 'flutter-c91c8.appspot.com',
    iosClientId: '327775764664-n9faega4pj87gt6ovr4qvhq8uusrkumh.apps.googleusercontent.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCooTlr8MPr8ssgBct0YRuyW_v2ogVSEKE',
    appId: '1:327775764664:ios:dbea90814185020459344d',
    messagingSenderId: '327775764664',
    projectId: 'flutter-c91c8',
    storageBucket: 'flutter-c91c8.appspot.com',
    iosClientId: '327775764664-n9faega4pj87gt6ovr4qvhq8uusrkumh.apps.googleusercontent.com',
    iosBundleId: 'com.example.chatApp',
  );
}
