plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.money_gestor"
    // 1. CORRECCIÓN: Subimos a la versión 36 como piden los plugins
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 2. CORRECCIÓN CRÍTICA: Activar Desugaring para las notificaciones
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.money_gestor"
        
        // Configuración mínima recomendada
        minSdk = flutter.minSdkVersion
        // 3. CORRECCIÓN: El target también debe subir a 36
        targetSdk = 36
        
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        
        // MultiDex sigue siendo necesario
        multiDexEnabled = true 
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
    // 4. CORRECCIÓN: Librería necesaria para que el Desugaring funcione
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    implementation("androidx.multidex:multidex:2.0.1")
}
