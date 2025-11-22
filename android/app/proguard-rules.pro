# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# WorkManager - Manter callback dispatcher e classes necessárias
-keep class com.beowulf.** { *; }
-keep class be.tramckrijte.workmanager.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.** { *; }
-dontwarn androidx.**

# SQFlite
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Timezone
-keep class com.example.timezone.** { *; }

# Manter todas as classes do pacote principal
-keep class com.example.simple_expense_tracker.** { *; }

# Evitar warnings comuns
-dontwarn kotlin.**
-dontwarn kotlinx.**
-dontwarn javax.annotation.**

