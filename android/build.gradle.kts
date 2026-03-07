buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Đây là nơi khai báo Google Services
        classpath("com.google.gms:google-services:4.4.1")

        // Có thể cần thêm Kotlin và Gradle Plugin nếu chưa có (đề phòng lỗi)
        classpath("com.android.tools.build:gradle:8.1.0") // Hoặc phiên bản tương ứng bạn đang dùng
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") // Hoặc phiên bản tương ứng
    }
}

// 2. Khối allprojects (Cấu hình cho các module con)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. Cấu hình thư mục build (Giữ nguyên code của bạn)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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