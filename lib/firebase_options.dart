import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZ6uNU8pRqvwaNwBs1jdSJWVoKq-xqku4',
    appId: '1:1020179078009:android:af316087b95bfdebe7eda8',
    messagingSenderId: '1020179078009',
    projectId: 'habit-flow-platform',
    authDomain: 'habit-flow-platform.firebaseapp.com',
    storageBucket: 'habit-flow-platform.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZ6uNU8pRqvwaNwBs1jdSJWVoKq-xqku4',
    appId: '1:1020179078009:android:af316087b95bfdebe7eda8',
    messagingSenderId: '1020179078009',
    projectId: 'habit-flow-platform',
    storageBucket: 'habit-flow-platform.firebasestorage.app',
  );
}
