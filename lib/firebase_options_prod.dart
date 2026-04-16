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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwP0t-yRuvRbDtYkRe5bhgHhF1AK_DgoU',
    appId: '1:34402393511:web:2a539ac8abc26f5a64aa82',
    messagingSenderId: '34402393511',
    projectId: 'finkoappmx',
    authDomain: 'finkoappmx.firebaseapp.com',
    databaseURL: 'https://finkoappmx-default-rtdb.firebaseio.com',
    storageBucket: 'finkoappmx.firebasestorage.app',
    measurementId: 'G-7Z02K9W7BH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjacGjy6-uR_znqtc1_f0yZMDuYq5VmJ0',
    appId: '1:34402393511:android:7c517e8c85de2d2864aa82',
    messagingSenderId: '34402393511',
    projectId: 'finkoappmx',
    databaseURL: 'https://finkoappmx-default-rtdb.firebaseio.com',
    storageBucket: 'finkoappmx.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA55XSOlu4RWfPfj7stPYCgJx3E2OkWGpw',
    appId: '1:34402393511:ios:56f100275510cf0f64aa82',
    messagingSenderId: '34402393511',
    projectId: 'finkoappmx',
    databaseURL: 'https://finkoappmx-default-rtdb.firebaseio.com',
    storageBucket: 'finkoappmx.firebasestorage.app',
    iosClientId:
        '34402393511-c944tnqagr0kfsuvpcvplsnnn1mc65ss.apps.googleusercontent.com',
    iosBundleId: 'com.example.finko',
  );
}
