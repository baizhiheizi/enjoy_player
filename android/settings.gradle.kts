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

    val isCi = System.getenv("GITHUB_ACTIONS") == "true"

    // Mirrors come first on networks where dl.google.com resets the TLS
    // handshake. The self-hosted runner pool sits behind that network, so CI
    // there opts in explicitly (ENABLE_MAVEN_MIRROR=1); a GitHub-hosted
    // runner leaves it off because a mirror 5xx disables the repository and
    // blocks fallback resolution.
    val useMirrors = !isCi || System.getenv("ENABLE_MAVEN_MIRROR") == "1"

    repositories {
        if (useMirrors) {
            // Mirrors first: avoids TLS/handshake failures to dl.google.com on
            // some networks (WSL2, corporate proxies, regions with restricted
            // Google Maven, and the self-hosted runner pool).
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/central") }
            maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
            maven { url = uri("https://maven.aliyun.com/repository/public") }
        }
        google()
        mavenCentral()
        if (isCi) {
            gradlePluginPortal()
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("com.android.library") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
