import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.childcarehub.childcarehub_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.childcarehub.childcarehub_flutter"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Enable crash reporting collection
        manifestPlaceholders["crashlyticsCollectionEnabled"] = true
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("MYAPP_RELEASE_KEY_ALIAS")) {
                keyAlias = keystoreProperties["MYAPP_RELEASE_KEY_ALIAS"] as String
                keyPassword = keystoreProperties["MYAPP_RELEASE_KEY_PASSWORD"] as String
                storeFile = file(keystoreProperties["MYAPP_RELEASE_STORE_FILE"] as String)
                storePassword = keystoreProperties["MYAPP_RELEASE_STORE_PASSWORD"] as String
            }
        }
    }

    buildTypes {
        debug {
            if (project.extensions.findByName("android") != null && project.hasProperty("applicationId")) {
                applicationIdSuffix = ".debug"
            }
            versionNameSuffix = "-debug"
            isDebuggable = true
            isMinifyEnabled = false
            manifestPlaceholders["crashlyticsCollectionEnabled"] = false
        }
        
        create("staging") {
            initWith(getByName("debug"))
            if (project.extensions.findByName("android") != null && project.hasProperty("applicationId")) {
                applicationIdSuffix = ".staging"
            }
            versionNameSuffix = "-staging"
            isDebuggable = true
            isMinifyEnabled = true
            manifestPlaceholders["crashlyticsCollectionEnabled"] = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            manifestPlaceholders["crashlyticsCollectionEnabled"] = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
