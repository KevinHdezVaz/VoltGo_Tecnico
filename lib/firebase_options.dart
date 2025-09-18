import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidOptions;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosOptions;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get _androidOptions {
    return FirebaseOptions(
      apiKey: dotenv.env['ANDROID_API_KEY'] ?? _throwMissingKey('ANDROID_API_KEY'),
      appId: dotenv.env['ANDROID_APP_ID'] ?? _throwMissingKey('ANDROID_APP_ID'),
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? _throwMissingKey('MESSAGING_SENDER_ID'),
      projectId: dotenv.env['PROJECT_ID'] ?? _throwMissingKey('PROJECT_ID'),
      storageBucket: dotenv.env['STORAGE_BUCKET'] ?? _throwMissingKey('STORAGE_BUCKET'),
    );
  }

  static FirebaseOptions get _iosOptions {
    return FirebaseOptions(
      apiKey: dotenv.env['IOS_API_KEY'] ?? _throwMissingKey('IOS_API_KEY'),
      appId: dotenv.env['IOS_APP_ID'] ?? _throwMissingKey('IOS_APP_ID'),
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? _throwMissingKey('MESSAGING_SENDER_ID'),
      projectId: dotenv.env['PROJECT_ID'] ?? _throwMissingKey('PROJECT_ID'),
      storageBucket: dotenv.env['STORAGE_BUCKET'] ?? _throwMissingKey('STORAGE_BUCKET'),
      iosBundleId: dotenv.env['IOS_BUNDLE_ID'] ?? _throwMissingKey('IOS_BUNDLE_ID'),
    );
  }

  static String _throwMissingKey(String key) {
    throw Exception('Missing environment variable: $key. Check your .env file.');
  }
}