import java.io.FileInputStream
import java.util.Properties

plugins {

    id("com.android.application")

    id("kotlin-android")

    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 FIREBASE
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {

    namespace = "com.premchemicals.nuklean"

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
            "com.premchemicals.nuklean"

        minSdk = flutter.minSdkVersion

        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
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
