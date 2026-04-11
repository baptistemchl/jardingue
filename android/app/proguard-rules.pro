## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Geolocator
-keep class com.baseflow.geolocator.** { *; }

## Play Core (in-app update + deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

## Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions
