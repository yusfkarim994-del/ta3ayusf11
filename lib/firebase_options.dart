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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8i_T9KnupgCD_POqvl2jc6BvQEhIHnZM',
    appId: '1:789086064752:android:aaec59f3d07ec6411d64b5',
    messagingSenderId: '789086064752',
    projectId: 'my-chat-app-daaf8',
    storageBucket: 'my-chat-app-daaf8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8i_T9KnupgCD_POqvl2jc6BvQEhIHnZM',
    appId: '1:789086064752:android:aaec59f3d07ec6411d64b5',
    messagingSenderId: '789086064752',
    projectId: 'my-chat-app-daaf8',
    storageBucket: 'my-chat-app-daaf8.firebasestorage.app',
    authDomain: 'my-chat-app-daaf8.firebaseapp.com',
  );
}
