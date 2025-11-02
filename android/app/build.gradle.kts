// ✅ HAPUS SEMUA FIREBASE/GOOGLE SERVICES DULU
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // ❌ HAPUS DULU: id("com.google.gms.google-services")
}

android {
    namespace = "com.example.koperasi_fresh"
    compileSdk = 34
    ndkVersion = "26.1.10909125"

    compileOptions {
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.koperasi_fresh"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // ❌ HAPUS DULU Firebase dependencies
    // implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    // implementation("com.google.firebase:firebase-analytics")
}