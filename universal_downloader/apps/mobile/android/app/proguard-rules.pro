# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter deferred components (optional Play Core references)
-dontwarn com.google.android.play.core.**

# Gson / JSON (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*

# Foreground service
-keep class com.pravera.flutter_foreground_task.** { *; }
