import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// === Load .env ===
val envFile = rootProject.file(".env")
val envProps = Properties()
if (envFile.exists()) {
    envFile.inputStream().use { envProps.load(it) }
}

val appId = envProps.getProperty("APP_ID", "com.example.school_parent_app")
val appName = envProps.getProperty("APP_NAME", "School Parent App")

android {
    namespace = appId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = appId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Auto-set label (replaces app_name dynamically)
    applicationVariants.all {
        outputs.all {
            val resFile = file("src/main/res/values/strings.xml")
            if (resFile.exists()) {
                val content = resFile.readText()
                if (content.contains("<string name=\"app_name\">")) {
                    val newContent = content.replace(
                        Regex("<string name=\"app_name\">.*?</string>"),
                        "<string name=\"app_name\">$appName</string>"
                    )
                    resFile.writeText(newContent)
                }
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
