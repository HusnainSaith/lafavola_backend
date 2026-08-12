plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = providers.environmentVariable("LA_FAVOLA_ANDROID_KEYSTORE_PATH").orNull
val releaseKeyAlias = providers.environmentVariable("LA_FAVOLA_ANDROID_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("LA_FAVOLA_ANDROID_KEY_PASSWORD").orNull
val releaseStorePassword = providers.environmentVariable("LA_FAVOLA_ANDROID_STORE_PASSWORD").orNull
val releaseSigningReady = listOf(releaseKeystorePath, releaseKeyAlias, releaseKeyPassword, releaseStorePassword)
    .all { !it.isNullOrBlank() }

android {
    namespace = "it.lafavola.customer"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.lafavola.customer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseSigningReady) signingConfigs.getByName("release") else null
        }
    }
}

flutter {
    source = "../.."
}
