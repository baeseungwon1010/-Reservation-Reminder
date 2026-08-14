allprojects {
    repositories {
        google()
        mavenCentral()
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

// 일부 플러그인(flutter_timezone 등)이 Java 11 / Kotlin 1.8 로 서로 다른 JVM 타깃을
// 지정해 "Inconsistent JVM Target Compatibility" 로 빌드가 깨진다.
// AGP 타입에 의존하지 않고, 핵심 Gradle 태스크 수준에서 Java·Kotlin 을 17 로 통일한다.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
