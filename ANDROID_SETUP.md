# Android setup (reminders + step counting)

Stage 4 adds four packages that need a few native Android settings.
**Do these edits in your own `android/` folder**, then run `flutter pub get`.

If anything here breaks your build and you are short of time, go back to the
Stage 2/3 version (it needs none of this). Stage 4 is an optional extra.

## 1. `android/app/src/main/AndroidManifest.xml`

Add these just inside `<manifest ...>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Add these inside `<application ...> ... </application>` (next to `<activity>`):

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

## 2. `android/app/build.gradle.kts` (or `build.gradle` on older projects)

`flutter_local_notifications` needs *core library desugaring* and Java 17.

**Kotlin DSL (`build.gradle.kts`):**

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    // If you have a kotlinOptions block, keep it at: jvmTarget = "17"
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**Groovy (`build.gradle`):**

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

`dependencies { ... }` is usually already at the bottom of the file; add the
`coreLibraryDesugaring` line inside it instead of making a second block.

## 3. Check

```
flutter pub get
flutter analyze
flutter test
flutter run            # real phone recommended for step counting
```

Notes
- The emulator has no real step sensor, so test automatic step counting on a phone.
- On Android 13+ the app asks for notification permission when you switch a reminder on,
  and for "Physical activity" when you switch on automatic step counting.
- If the build says "requires core library desugaring", step 2 was not applied.
