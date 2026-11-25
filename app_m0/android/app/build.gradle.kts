plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
// Native tests use their own Android sandbox, including their SQLite files.
// The environment flag is set only for the explicit integration-test command.
val fishcareNativeTest = System.getenv("FISHCARE_NATIVE_TEST") == "1"
android {
    namespace = "id.ac.fishcare.m0"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "id.ac.fishcare.m0"
        if (fishcareNativeTest) applicationIdSuffix = ".tests"
        manifestPlaceholders["fishcareAppLabel"] = if (fishcareNativeTest) "FishCare Uji" else "FishCare V2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
flutter { source = "../.." }
