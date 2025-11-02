// ✅ TAMBAH INI DI BARIS PALING ATAS
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0")
        classpath("com.google.gms:google-services:4.4.2") // ✅ TAMBAH INI
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ SEKARANG SUDAH BISA
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "com.example.koperasi_fresh"
    compileSdk = 34 // ✅ SET MANUAL, JANGAN PAKAI flutter.compileSdkVersion
    ndkVersion = "26.1.10909125" // ✅ SET MANUAL

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
        minSdk = 21 // ✅ SET MANUAL
        targetSdk = 34 // ✅ SET MANUAL
        versionCode = 1 // ✅ SET MANUAL
        versionName = "1.0.0" // ✅ SET MANUAL
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
}