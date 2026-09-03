---
name: Imported app toolchains
description: Environment-specific setup lessons for this imported Laravel plus Flutter project.
---

The imported project needs the runtime versions declared by its dependencies, not only the versions present in the generated workflow. The workflow module declaration can override an installed Nix package, so keep the PHP module aligned with Composer's platform requirement. Flutter analysis and web builds can pass while a desktop native build still needs platform libraries such as libsecret.

**Why:** The initial workflow selected PHP 8.2 even though the installed Laravel dependencies required PHP 8.4.1+, and Linux Flutter compilation separately required libsecret for secure storage.

**How to apply:** When setting up or debugging this project, check the declared toolchain configuration and run the actual Flutter target build; do not treat `flutter analyze` alone as proof that native targets compile.

For this workspace, installing `android-tools` provides `adb` only; Flutter Android builds still require a separately configured Android SDK with the required platform and build-tools packages. Do not treat platform-tools availability as Android SDK availability.

**Why:** The clean APK build stopped at Flutter's SDK detection before Gradle compilation, while Java/Gradle compatibility was already confirmed.

**How to apply:** Keep Android build status explicitly blocked until `flutter doctor` detects the SDK and a clean `flutter build apk --debug` succeeds.