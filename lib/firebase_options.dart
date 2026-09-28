// File generated manually based on Firebase project config
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDfyw_LdBBhImg2cqa1qHr4qaRopqcBzxY',
    appId: '1:35490038050:web:d6e4492cd45460be9da57b',
    messagingSenderId: '35490038050',
    projectId: 'qadaa-app-ea768',
    authDomain: 'qadaa-app-ea768.firebaseapp.com',
    storageBucket: 'qadaa-app-ea768.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfyw_LdBBhImg2cqa1qHr4qaRopqcBzxY',
    appId: '1:35490038050:android:54fca5c17a0e67f99da57b',
    messagingSenderId: '35490038050',
    projectId: 'qadaa-app-ea768',
    storageBucket: 'qadaa-app-ea768.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDfyw_LdBBhImg2cqa1qHr4qaRopqcBzxY',
    appId: '1:35490038050:android:54fca5c17a0e67f99da57b',
    messagingSenderId: '35490038050',
    projectId: 'qadaa-app-ea768',
    storageBucket: 'qadaa-app-ea768.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDfyw_LdBBhImg2cqa1qHr4qaRopqcBzxY',
    appId: '1:35490038050:android:54fca5c17a0e67f99da57b',
    messagingSenderId: '35490038050',
    projectId: 'qadaa-app-ea768',
    storageBucket: 'qadaa-app-ea768.firebasestorage.app',
  );
}
