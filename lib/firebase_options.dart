import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDBqy3qEXi6fcLk8YkE1Bs9vAboX5tq0E',
    appId: '1:790773540431:web:e7fdd3dcc6cf743af86c3a',
    messagingSenderId: '790773540431',
    projectId: 'weasly-personal-budget-t-dc51f',
    authDomain: 'weasly-personal-budget-t-dc51f.firebaseapp.com',
    storageBucket: 'weasly-personal-budget-t-dc51f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDBqy3qEXi6fcLk8YkE1Bs9vAboX5tq0E',
    appId: '1:790773540431:android:e7fdd3dcc6cf743af86c3a',
    messagingSenderId: '790773540431',
    projectId: 'weasly-personal-budget-t-dc51f',
    storageBucket: 'weasly-personal-budget-t-dc51f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCDBqy3qEXi6fcLk8YkE1Bs9vAboX5tq0E',
    appId: '1:790773540431:ios:e7fdd3dcc6cf743af86c3a',
    messagingSenderId: '790773540431',
    projectId: 'weasly-personal-budget-t-dc51f',
    storageBucket: 'weasly-personal-budget-t-dc51f.firebasestorage.app',
    iosBundleId: 'com.weasly.app.weasly',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCDBqy3qEXi6fcLk8YkE1Bs9vAboX5tq0E',
    appId: '1:790773540431:ios:e7fdd3dcc6cf743af86c3a',
    messagingSenderId: '790773540431',
    projectId: 'weasly-personal-budget-t-dc51f',
    storageBucket: 'weasly-personal-budget-t-dc51f.firebasestorage.app',
    iosBundleId: 'com.weasly.app.weasly',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCDBqy3qEXi6fcLk8YkE1Bs9vAboX5tq0E',
    appId: '1:790773540431:web:e7fdd3dcc6cf743af86c3a',
    messagingSenderId: '790773540431',
    projectId: 'weasly-personal-budget-t-dc51f',
    authDomain: 'weasly-personal-budget-t-dc51f.firebaseapp.com',
    storageBucket: 'weasly-personal-budget-t-dc51f.firebasestorage.app',
  );
}
