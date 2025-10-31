plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.koperasi_fresh"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion

    compileOptions {
        coreLibraryDesugaringEnabled true  // ✅ TAMBAH INI
        sourceCompatibility = JavaVersion.VERSION_1_8  // ✅ UBAH 11 → 1_8
        targetCompatibility = JavaVersion.VERSION_1_8  // ✅ UBAH 11 → 1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"  // ✅ UBAH VERSION_11 → "1.8"
    }

    defaultConfig {
        applicationId = "com.example.koperasi_fresh"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInteger()
        versionName = flutter.versionName
        multiDexEnabled = true  // ✅ TAMBAH INI
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  // ✅ TAMBAH INI
}