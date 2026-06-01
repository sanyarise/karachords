allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(
    rootProject.layout.buildDirectory.dir("../../build").get()
)

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
