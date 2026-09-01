import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase Web non configuré.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plateforme non configurée pour Firebase.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsNaxQd5qCA7QC33IdAajHCqby6SWtzHo',
    appId: '1:259034172860:android:032f5132f88d234e2fafb9',
    messagingSenderId: '259034172860',
    projectId: 'les-twiix',
    storageBucket: 'les-twiix.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDccPzThbt4puILyurFZwRsmay7TmS8jNw',
    appId: '1:259034172860:ios:3149a0cc5c84d31f2fafb9',
    messagingSenderId: '259034172860',
    projectId: 'les-twiix',
    storageBucket: 'les-twiix.firebasestorage.app',
    iosBundleId: 'com.lestwiix.lesTwiixApp',
  );
}
