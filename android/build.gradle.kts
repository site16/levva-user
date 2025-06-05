// android/build.gradle.kts
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}

plugins {
    // não defina a versão aqui para evitar conflito
    id("com.google.gms.google-services") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
