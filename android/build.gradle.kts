import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

val isCi = System.getenv("GITHUB_ACTIONS") == "true"

// See settings.gradle.kts: mirrors are opt-in for CI so the self-hosted
// runner pool (where dl.google.com resets the TLS handshake) can reach
// Google Maven artifacts through a mirror, while GitHub-hosted runners
// keep the plain google()/mavenCentral() path.
val useMirrors = !isCi || System.getenv("ENABLE_MAVEN_MIRROR") == "1"

allprojects {
    repositories {
        if (useMirrors) {
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/central") }
        }
        google()
        mavenCentral()
    }
}

// Plugins (e.g. file_picker) ship their own buildscript { repositories { google() } }.
// Prepend the same mirrors so AGP/classpath deps resolve when dl.google.com fails TLS.
subprojects {
    buildscript {
        repositories {
            if (useMirrors) {
                maven { url = uri("https://maven.aliyun.com/repository/google") }
                maven { url = uri("https://maven.aliyun.com/repository/central") }
            }
            google()
            mavenCentral()
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Flutter plugins declare mixed Java levels (1.8, 11, 17). Do not force Kotlin to 17 globally —
// that breaks AGP's Java/Kotlin compatibility check (e.g. sign_in_with_apple: Java 1.8, Kotlin 17).
// After all projects are evaluated, align each KotlinCompile jvmTarget to android.compileOptions.
gradle.projectsEvaluated {
    subprojects {
        val javaVersion =
            runCatching {
                extensions.findByType(BaseExtension::class.java)?.compileOptions?.sourceCompatibility
            }.getOrNull() ?: JavaVersion.VERSION_1_8
        val jvmTarget =
            when (javaVersion) {
                JavaVersion.VERSION_17 -> JvmTarget.JVM_17
                JavaVersion.VERSION_11 -> JvmTarget.JVM_11
                else -> JvmTarget.JVM_1_8
            }
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(jvmTarget)
        }
    }
}
