import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCh86fSsDR6w4Z-fpRlZ36QP-l766O09zI',
    authDomain: 'neosante-24dc4.firebaseapp.com',
    projectId: 'neosante-24dc4',
    storageBucket: 'neosante-24dc4.appspot.com',
    messagingSenderId: '73077398421',
    appId: '1:73077398421:web:479bc62ffd23d9427df49c',
    measurementId: 'G-108W856222',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCh86fSsDR6w4Z-fpRlZ36QP-l766O09zI',
    appId: '1:73077398421:android:placeholder',
    messagingSenderId: '73077398421',
    projectId: 'neosante-24dc4',
    storageBucket: 'neosante-24dc4.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCh86fSsDR6w4Z-fpRlZ36QP-l766O09zI',
    appId: '1:73077398421:ios:placeholder',
    messagingSenderId: '73077398421',
    projectId: 'neosante-24dc4',
    storageBucket: 'neosante-24dc4.appspot.com',
    iosClientId: '1:73077398421:ios:placeholder',
    iosBundleId: 'com.example.app',
  );
}
