import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Replace with real values from `flutterfire configure`.
/// TODO: Run `flutterfire configure` to generate the real config.
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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY-API-KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:web:dummy'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'familyhub-dummy'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'familyhub-dummy.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'familyhub-dummy.appspot.com'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY-API-KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:android:dummy'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'familyhub-dummy'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'familyhub-dummy.appspot.com'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY-API-KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:ios:dummy'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'familyhub-dummy'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'familyhub-dummy.appspot.com'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.example.familyhub'),
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY-API-KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:ios:dummy'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'familyhub-dummy'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'familyhub-dummy.appspot.com'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.example.familyhub'),
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY-API-KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:web:dummy'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'familyhub-dummy'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'familyhub-dummy.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'familyhub-dummy.appspot.com'),
  );
}
