# Build the Stride release bundle on your Mac

The Linux VM can't finish the Gradle build (its localhost networking is
broken — full story in the chat). Your Mac can do it in minutes: unzip this
kit anywhere and run one command.

## What you need

- Flutter SDK (any recent 3.x)
- Android SDK with cmdline-tools + platform-tools, licenses accepted
- Java 17 (Android Studio's bundled JBR works)

**If Flutter isn't installed yet** (one-time, ~10 min):

```bash
# 1. Install Flutter + Android command-line tools
brew install --cask flutter
brew install --cask android-commandlinetools  # or install Android Studio instead

# 2. Install the Android SDK pieces and accept licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
flutter doctor --android-licenses
```

## Build (works whether or not Flutter was already installed)

```bash
cd /path/to/stride-app/proj     # the unzipped kit: proj/ and release/ must sit side by side
flutter build appbundle --release
```

That's it. On a normal machine this takes a few minutes the first time
(Gradle downloads dependencies) and under a minute after that.

- The signed AAB lands at:
  `proj/build/app/outputs/bundle/release/app-release.aab`
- It's already signed with the release keystore (`release/stride-release.keystore`,
  alias `stride`, credentials in `release/keystore-info.txt` — wired up via
  `proj/android/key.properties`).

**If Gradle complains about the Java version:** point it at Android Studio's
bundled runtime, e.g. in `proj/android/gradle.properties` add:

```
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

## After the build

1. **Back up `release/`** (keystore + keystore-info.txt). The SAME key is
   required for every future update — lose it and Google rejects updates.
2. Send the AAB back here (drop it in chat, or use the Mac app's file upload).
   Next step is the Play Console upload — the full walkthrough is in
   `docs/PUBLISH-CHECKLIST.md`.
3. **Note:** this AAB uses Google's TEST ad IDs. Once you send the real AdMob
   App ID + 3 ad-unit IDs, it's one more `flutter build appbundle --release`
   to produce the final monetized bundle.

## Still needed from you (same as before)

- Real AdMob App ID + 3 ad-unit IDs (banner, interstitial, rewarded)
- Support email (privacy policy currently has a placeholder)
- Public URL hosting the privacy policy
- Google Play developer account ($25 + ID check)
- Personal vs organization account decision
