plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // ⚠️ Não coloque a versão aqui para evitar conflitos
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.levva_app_new"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Remova esta linha se não usa NDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.levva_app_new"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))

    // Ative os SDKs conforme necessário
    // implementation("com.google.firebase:firebase-auth-ktx")
    // implementation("com.google.firebase:firebase-analytics-ktx")
}

