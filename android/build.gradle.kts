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
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val ns = getNamespace.invoke(android)
                    if (ns == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val safeGroup = if (project.group.toString() == "unspecified" || project.group.toString().isEmpty()) "com.example.${project.name}" else project.group.toString()
                        setNamespace.invoke(android, safeGroup)
                        println("ANTIGRAVITY: Forced namespace for ${project.name} to $safeGroup")
                    }
                } catch (e: Exception) {
                    println("ANTIGRAVITY: Failed to force namespace: $e")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
