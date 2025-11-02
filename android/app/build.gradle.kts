plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ TAMBAH INI
}

android {
    namespace = "com.example.koperasi_ksmi_new"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ✅ UBAH INI - jangan pakai com.example
        applicationId = "com.ksmi.koperasi"
        minSdk = 21 // ✅ PASTIKAN MIN SDK 21
        targetSdk = 33 // ✅ TURUNKAN KE 33 (lebih stabil)
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // ✅ MATIKAN MINIFY & SHRINK
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
}