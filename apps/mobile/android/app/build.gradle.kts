plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.deenapp.mobile"
    // permission_handler_android needs API 37 or newer to compile against.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.deenapp.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    sourceSets {
        // The instrumented arbiter test reads the same vector files the Dart planner tests use,
        // so the Kotlin and Dart arbiters cannot drift apart (plan: shared vectors).
        getByName("androidTest") {
            assets.srcDir("../../../../packages/schedule_planner/test_vectors")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Notification, ServiceCompat and ContextCompat helpers. No Google Play Services, Firebase
    // or Play Core anywhere (FR-001, spike S4).
    implementation("androidx.core:core:1.13.1")
    // The Pigeon-generated Kotlin code (generated/*.g.kt) imports kotlinx.coroutines for its
    // suspend (@async) APIs, so the app must depend on it explicitly. Apache-2.0.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // Versions match what Flutter's integration_test plugin already puts on the app's
    // runtime classpath (runner 1.3.0, rules 1.2.0); newer ones fail Gradle's
    // consistent-resolution check.
    androidTestImplementation("androidx.test:runner:1.3.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
    androidTestImplementation("androidx.test.ext:junit:1.1.2")
}

// flutter_local_notifications asks for core library desugaring, which only matters
// for devices below API 26. This app's minSdk is 26, the plugin is used on iOS only,
// and the desugaring library (desugar_jdk_libs) is GPL with the Classpath Exception,
// which the constitution's license rule (principle 10) does not allow us to link. So
// the AAR metadata check is switched off instead of enabling desugaring.
tasks.matching { it.name.matches(Regex("check.*AarMetadata")) }.configureEach {
    enabled = false
}
