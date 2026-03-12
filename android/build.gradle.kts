allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://central.sonatype.com/repository/maven-snapshots/")
        }
    }
    configurations.configureEach {
        resolutionStrategy {
            force(
                "androidx.camera:camera-lifecycle:1.5.0",
                "androidx.camera:camera-camera2:1.5.0",
                "androidx.camera:camera-video:1.5.0",
                "androidx.camera:camera-core:1.5.0",
                "androidx.camera:camera-view:1.5.0"
            )
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
