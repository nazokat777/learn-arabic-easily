import java.util.Properties

// Chiqarish (release) imzosi. `key.properties` bo'lsa — o'sha kalit bilan,
// bo'lmasa debug kalit bilan imzolanadi (mahalliy `flutter run --release`
// ishlashi uchun).
//
// NEGA KERAK: ilgari release APK ham DEBUG kalit bilan imzolanardi. Debug
// kalit har mashinada boshqacha — GitHub Actions esa har yugurishda yangi
// mashina, ya'ni har APK boshqa imzo bilan chiqardi. Android boshqa imzoli
// yangilanishni o'rnatmaydi: telefonda «Приложение не установлено» chiqadi
// va foydalanuvchi eskisini o'chirishga majbur bo'ladi (taraqqiyoti bilan
// birga). Barqaror kalit shu muammoni butunlay yopadi.
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.arabtili.learn_arabic"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
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
