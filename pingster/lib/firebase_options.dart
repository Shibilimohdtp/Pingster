// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyAyWl69hA--QD9ICkpuBTc6Pm5tJ94hZjo',
    appId: '1:812692124061:web:4203095128f374c9027f74',
    messagingSenderId: '812692124061',
    projectId: 'pingster-e0008',
    authDomain: 'pingster-e0008.firebaseapp.com',
    storageBucket: 'pingster-e0008.appspot.com',
    measurementId: 'G-FST7JD7M6S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBeCvfvEsQqUilkExVn79yIbsMnsFNijQE',
    appId: '1:812692124061:android:fc95730990edd1f0027f74',
    messagingSenderId: '812692124061',
    projectId: 'pingster-e0008',
    storageBucket: 'pingster-e0008.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB_cE8Lwuhyg_8urDWalmJIhvCDgrQurtg',
    appId: '1:812692124061:ios:c6c3a63fd92352a5027f74',
    messagingSenderId: '812692124061',
    projectId: 'pingster-e0008',
    storageBucket: 'pingster-e0008.appspot.com',
    iosBundleId: 'com.example.pingster',
  );
}
