plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") version "2.1.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.appointment_booking_system"
    compileSdk = 35 
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.appointment_booking_system"
        minSdk = 23
        targetSdk = 35 // Or flutter.targetSdkVersion
        versionCode = 1 // Replace with flutter.versionCode if available
        versionName = "1.0" // Replace with flutter.versionName if available
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))

    // Add the dependencies for Firebase products you want to use
    implementation("com.google.firebase:firebase-analytics")
    // Add others as needed, like:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-storage")
}
