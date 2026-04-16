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
    apiKey: 'AIzaSyAiHONSeXAlG4mSOlvljzW2gX1HFny94ss',
    appId: '1:654834705056:web:3f507f811d64a5005adfc5',
    messagingSenderId: '654834705056',
    projectId: 'finkoappmx-dev',
    authDomain: 'finkoappmx-dev.firebaseapp.com',
    storageBucket: 'finkoappmx-dev.firebasestorage.app',
    measurementId: 'G-B3RC4BCS3Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlSzMuro-yjB3q3WFKnsKp0GI7lsnzv1s',
    appId: '1:654834705056:android:3c08c5d9934d85255adfc5',
    messagingSenderId: '654834705056',
    projectId: 'finkoappmx-dev',
    storageBucket: 'finkoappmx-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1k9P3OJ53epDzQlxk80VAF93AcJqWVaE',
    appId: '1:654834705056:ios:7cb23d1773f21ea45adfc5',
    messagingSenderId: '654834705056',
    projectId: 'finkoappmx-dev',
    storageBucket: 'finkoappmx-dev.firebasestorage.app',
    iosBundleId: 'com.example.finko.dev',
  );
}
