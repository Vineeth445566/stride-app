pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Local caching proxy for sandboxed builds (remove for normal builds)
        maven("http://127.0.0.1:8890") {
            isAllowInsecureProtocol = true
        }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Local caching proxy for project dependencies (sandboxed builds only)
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // Local caching proxy for sandboxed builds (remove for normal builds)
        maven("http://127.0.0.1:8890") {
            isAllowInsecureProtocol = true
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
