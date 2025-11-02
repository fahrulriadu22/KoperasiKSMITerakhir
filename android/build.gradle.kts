// ✅ PERBAIKI DENGAN SYNTAX KOTLIN DSL YANG BENAR
buildscript {
    val kotlinVersion = "1.9.24"
    
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ PERBAIKI SYNTAX DI SINI - PAKAI File()
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app") // ✅ PAKAI STRING, BUKAN CHARACTER LITERAL
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}