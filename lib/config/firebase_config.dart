import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  // Web configuration
  static String get apiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get authDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get projectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get storageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get messagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get appId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get measurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';
  
  // Android configuration
  static String get androidApiKey => dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? apiKey;
  static String get androidAppId => dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? appId;
  
  // iOS configuration
  static String get iosApiKey => dotenv.env['FIREBASE_IOS_API_KEY'] ?? apiKey;
  static String get iosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? appId;
  static String get iosClientId => dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '';
  static String get iosBundleId => 'com.example.diaryApp'; // Replace with your actual bundle ID
  
  // Common configuration
  static String get databaseURL => 'https://${projectId}.firebaseio.com';
  static String get storageBucketURL => 'gs://${storageBucket}';
}
