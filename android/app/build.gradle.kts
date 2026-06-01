plugins {

    id("com.android.application")

    id("kotlin-android")

    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 FIREBASE
    id("com.google.gms.google-services")
}

android {

    namespace = "com.example.prem_chemicals_app"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {

        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17

        // 🔥 REQUIRED
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {

        jvmTarget =
            JavaVersion.VERSION_17.toString()
    }

    defaultConfig {

        applicationId =
            "com.example.prem_chemicals_app"

        minSdk = flutter.minSdkVersion

        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName(
                    "debug"
                )
        }
    }
}

dependencies {

    // 🔥 REQUIRED FOR NOTIFICATIONS
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

flutter {

    source = "../.."
}
