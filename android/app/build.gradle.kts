plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ TAMBAH INI
}

android {
    namespace = "com.ksmi.koperasi"
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
    // ✅ PERBAIKI SYNTAX KOTLIN DSL - gunakan tanda kurung bukan kutip
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24")
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    
    // ✅ PERBAIKI SYNTAX JUGA
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
}