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

subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByName("android")
        try {
            android.javaClass
                .getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                .invoke(android, 36)
        } catch (_: Throwable) {
            try {
                android.javaClass
                    .getMethod("setCompileSdkVersion", Int::class.java)
                    .invoke(android, 36)
            } catch (_: Throwable) {
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
