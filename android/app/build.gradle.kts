plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Desugaring allows you to use modern Java features on older Android versions
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
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
    }

    buildTypes {
        release {
            // NOTE: Ensure you create a real release signingConfig before publishing!
            signingConfig = signingConfigs.getByName("debug")
            
            // Recommended: Shrink and optimize code for offline AI models
            isMinifyEnabled = false 
            isShrinkResources = false
        }
    }
}

dependencies {
    // Updated to the latest stable desugaring version for 2026
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
