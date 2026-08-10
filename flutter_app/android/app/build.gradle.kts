plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release artifacts must never silently fall back to the debug signing key.
// Supply these values through the build environment in CI or the publishing
// system; no signing material belongs in the repository.
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val uploadStoreFile = System.getenv("TRADEX_UPLOAD_STORE_FILE")
val uploadStorePassword = System.getenv("TRADEX_UPLOAD_STORE_PASSWORD")
val uploadKeyAlias = System.getenv("TRADEX_UPLOAD_KEY_ALIAS")
val uploadKeyPassword = System.getenv("TRADEX_UPLOAD_KEY_PASSWORD")

android {
    namespace = "ps.tradex.app"
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
        applicationId = "ps.tradex.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (isReleaseBuild) {
                require(!uploadStoreFile.isNullOrBlank()) {
                    "Missing TRADEX_UPLOAD_STORE_FILE for the release signing configuration."
                }
                require(!uploadStorePassword.isNullOrBlank()) {
                    "Missing TRADEX_UPLOAD_STORE_PASSWORD for the release signing configuration."
                }
                require(!uploadKeyAlias.isNullOrBlank()) {
                    "Missing TRADEX_UPLOAD_KEY_ALIAS for the release signing configuration."
                }
                require(!uploadKeyPassword.isNullOrBlank()) {
                    "Missing TRADEX_UPLOAD_KEY_PASSWORD for the release signing configuration."
                }

                val keystore = file(uploadStoreFile!!)
                require(keystore.isFile) {
                    "TRADEX_UPLOAD_STORE_FILE does not point to an existing keystore."
                }
                storeFile = keystore
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
