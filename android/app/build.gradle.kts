plugins {
    id("com.android.application")
<<<<<<< HEAD
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
=======
    id("com.google.gms.google-services")
    id("kotlin-android")
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.example.naviapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
=======
    namespace = "com.example.mobile_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Desugaring allows you to use modern Java features on older Android versions
        isCoreLibraryDesugaringEnabled = true
        
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.naviapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
=======
        applicationId = "com.example.mobile_app"
        // minSdk 21 is good, but note that some LiteRT-LM features perform better on 23+
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true

        // CRITICAL for Offline AI: Ensures the app only builds for supported 
        // phone architectures, reducing file size significantly.
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
    }

    buildTypes {
        release {
<<<<<<< HEAD
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
=======
            // NOTE: Ensure you create a real release signingConfig before publishing!
            signingConfig = signingConfigs.getByName("debug")
            
            // Recommended: Shrink and optimize code for offline AI models
            isMinifyEnabled = false 
            isShrinkResources = false
>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
        }
    }
}

<<<<<<< HEAD
=======
dependencies {
    // Updated to the latest stable desugaring version for 2026
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

>>>>>>> 8a35f843624a455ebaf6c1defb4b1077f73e75bc
flutter {
    source = "../.."
}
