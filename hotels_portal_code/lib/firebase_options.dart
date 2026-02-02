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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyC6DEy1phl6z-0owQ8u0RygFtvherJFvjA',
    appId: '1:863262733039:web:3e598ca2d5c9bee2a7e11a',
    messagingSenderId: '863262733039',
    projectId: 'graduation-project-5f333',
    authDomain: 'graduation-project-5f333.firebaseapp.com',
    databaseURL: 'https://graduation-project-5f333-default-rtdb.firebaseio.com',
    storageBucket: 'graduation-project-5f333.firebasestorage.app',
    measurementId: 'G-78FJYRKBKF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOhD-HSqG_rFDZsr_0ah6kP1iH8OXKEqs',
    appId: '1:863262733039:android:af96d9f1b269cf0da7e11a',
    messagingSenderId: '863262733039',
    projectId: 'graduation-project-5f333',
    databaseURL: 'https://graduation-project-5f333-default-rtdb.firebaseio.com',
    storageBucket: 'graduation-project-5f333.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDOhD-HSqG_rFDZsr_0ah6kP1iH8OXKEqs',
    appId: '1:863262733039:ios:9fe7ba69fe1b9c3fa7e11a',
    messagingSenderId: '863262733039',
    projectId: 'graduation-project-5f333',
    storageBucket: 'graduation-project-5f333.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC6DEy1phl6z-0owQ8u0RygFtvherJFvjA',
    appId: '1:863262733039:web:8aef3a601dd767c9a7e11a',
    messagingSenderId: '863262733039',
    projectId: 'graduation-project-5f333',
    authDomain: 'graduation-project-5f333.firebaseapp.com',
    databaseURL: 'https://graduation-project-5f333-default-rtdb.firebaseio.com',
    storageBucket: 'graduation-project-5f333.firebasestorage.app',
    measurementId: 'G-E4RPV8CT8V',
  );

}