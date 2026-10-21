import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}
val keys = Properties()
val keyFile = rootProject.file("key.properties")
if (keyFile.exists()) keys.load(FileInputStream(keyFile))
android {
    namespace = "com.karya.studentplanner"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "com.karya.studentplanner" // PROVISIONAL: publisher must confirm before first upload
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    signingConfigs {
        create("release") {
            if (keyFile.exists()) {
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
                storeFile = keys.getProperty("storeFile")?.let { file(it) }
                storePassword = keys.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        getByName("release") {
            if (keyFile.exists()) signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
flutter { source = "../.." }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
