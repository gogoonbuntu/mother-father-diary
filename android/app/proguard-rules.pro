# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }

# Google Mobile Ads
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }
-keep class com.google.android.gms.internal.ads.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.FirebaseAnalytics { *; }
-keep class com.google.firebase.analytics.ktx.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.FirebaseInstanceId { *; }

# Firebase Database
-keep class com.google.firebase.database.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Keep the version of play-services-ads-identifier that is being used
-keep class com.google.android.gms.ads.identifier.** { *; }

# Keep the version of play-services-basement that is being used
-keep class com.google.android.gms.common.** { *; }

# Keep the version of play-services-tasks that is being used
-keep class com.google.android.gms.tasks.** { *; }

# Keep the version of play-services-measurement that is being used
-keep class com.google.android.gms.measurement.** { *; }

# Keep the version of play-services-measurement-api that is being used
-keep class com.google.android.gms.measurement.api.** { *; }

# Keep the version of play-services-measurement-sdk that is being used
-keep class com.google.android.gms.measurement.sdk.** { *; }

# Keep the version of play-services-measurement-impl that is being used
-keep class com.google.android.gms.measurement.internal.** { *; }

# Keep the version of play-services-measurement-sdk-api that is being used
-keep class com.google.android.gms.measurement.sdk.api.** { *; }

# Play Core Library (dontwarn for deprecated play-core references from Flutter engine)
-dontwarn com.google.android.play.core.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.internal.** { *; }
