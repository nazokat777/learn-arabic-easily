import java.util.Properties

// Chiqarish imzosi — asosiy ilova bilan BIR XIL kalit (key.properties),
// shunda qobiq eski ilovaning USTIGA yangilanish sifatida o'rnatiladi
// (applicationId ham bir xil). Kalit bo'lmasa debug imzo bilan.
val kalitFayli = rootProject.file("key.properties")
val kalit = Properties().apply {
    if (kalitFayli.exists()) kalitFayli.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "uz.arabtili.learn_arabic"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "uz.arabtili.learn_arabic"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (kalitFayli.exists()) {
            create("release") {
                storeFile = file(kalit.getProperty("storeFile"))
                storePassword = kalit.getProperty("storePassword")
                keyAlias = kalit.getProperty("keyAlias")
                keyPassword = kalit.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (kalitFayli.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
