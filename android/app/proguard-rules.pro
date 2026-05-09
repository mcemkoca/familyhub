# Flutter & Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

# Hive — keep models and the correct package
-keep class com.miro.familyhub.** { *; }
-dontwarn com.miro.familyhub.**

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (deferred components references these but we don't use them)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ML Kit text recognition (optional language packs)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Stripe push provisioning
-dontwarn com.stripe.android.pushProvisioning.**

# ── Additional keep rules for release build stability ──

# flutter_secure_storage + AndroidX Security
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Supabase / gotrue / realtime / postgrest
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class kotlinx.serialization.** { *; }
-dontwarn io.ktor.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.api.client.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# speech_to_text
-keep class com.csdcorp.speech_to_text.** { *; }

# Stripe
-keep class com.stripe.android.** { *; }

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# device_info_plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Crashlytics line numbers
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# flutter_contacts
-keep class com.github.sarbagyastha.** { *; }
-keep class kotlin.** { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Local Auth
-keep class androidx.biometric.** { *; }

# Prevent obfuscation of model classes
-keep class com.familyhub.app.models.** { *; }
-keepclassmembers class com.familyhub.app.models.** { *; }

# Keep generic signatures of TypeToken and subclasses (Gson / Supabase JSON)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
