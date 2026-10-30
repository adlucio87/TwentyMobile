# Flutter Wrapper & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.**

# Attributes & Annotations
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-dontwarn com.google.errorprone.annotations.**

# Flutter Wrapper for Google ML Kit
-dontwarn com.google.mlkit.vision.text.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Hive
-keep class io.hivedb.hive.** { *; }
-dontwarn io.hivedb.hive.**

# Secure Storage
-keep class com.it_verify.flutter_secure_storage.** { *; }
-dontwarn com.it_verify.flutter_secure_storage.**

# Gson / TypeToken (fixes flutter_local_notifications scheduled notifications crash in Release/R8)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
