# Publishing Stride to Google Play — checklist

Two things only YOU can do (Google requires the account owner):
steps 1 and 2. Everything else is already prepared in this folder.

## 1. Create your Google Play developer account (~15 min + $25)
- Go to https://play.google.com/console and sign up with your Google account.
- Pay the **$25 one-time registration fee** (this is Google's fee — the app
  itself was built with 100% free tools).
- Verify your identity with a government ID (required by Google).
- Choose account type:
  - **Personal**: simplest, but your first app must pass a **closed test with
    at least 14 testers for 14 days** before production release.
  - **Organization**: needs a free D-U-N-S number (takes a few days), skips
    the 14-day closed-test requirement.

## 2. Create your free AdMob account (for REAL ads)
- Sign up at https://admob.google.com with the same Google account.
- Add your app → create 3 ad units: **Banner**, **Interstitial**, **Rewarded**.
- Send me the 3 ad-unit IDs + the AdMob App ID. I will swap them into the app
  (currently it uses Google's TEST ad IDs) and rebuild the release bundle.
  - Or edit `lib/core/constants.dart` and `android/app/src/main/AndroidManifest.xml`
    yourself and run `flutter build appbundle --release`.

## 3. Build the release bundle (blocked on build infrastructure, 2026-10-10)
- The signed release bundle has NOT been built yet. The app source is complete
  (`flutter analyze` passes) but the VM's Gradle build is blocked by a
  localhost-networking issue (see `BUILD-INFRA-STATE.md` for details).
- Once built, the bundle goes in `release/stride-1.0.0.aab`.
- The bundle must be signed with the release keystore in `release/`.
  **Back up `release/keystore-info.txt` + `stride-release.keystore` — you need
  the SAME key for every future update, or Google will reject them.**
- In Play Console: Create app → name "Stride - Step Counter", default language
  English, app type "App", free.
- Go to **Release → Production** (or **Testing → Closed testing** for a
  personal account's first release) → Create release → upload the AAB.

## 4. Complete the Play Console questionnaires
- **Store listing**: copy text from `docs/store-listing.md`; upload icon,
  feature graphic (in `assets/store/`), and 2+ phone screenshots.
- **Privacy policy**: paste the hosted URL (the app's in-app link already
  points at it).
- **App content**: content rating questionnaire, target audience, "contains ads"
  → YES, data safety form (no data collected by the app itself; AdMob SDK
  handles the advertising ID per Google's policy), app access (no login needed).
- **App signing**: enroll in Play App Signing (recommended; Google manages the
  final signing key).

## 5. Roll out
- Personal account: run the 14-day closed test first (share the test link with
  14+ testers), then promote to production.
- Review usually takes 1–7 days. You'll get an email when it's live.

## Files in this folder
- `release/` — keystore + keystore-info.txt (**keep safe**); the AAB/APK go here once built
- `assets/store/icon-512.png`, `assets/store/feature-graphic.png` — listing art
- `assets/store/screenshots/` — 4 phone screenshots (PNG, AI-generated mockups)
- `docs/store-listing.md` — title, descriptions, declarations
- `docs/privacy-policy.md` — privacy policy text
- `proj/` — full Flutter source code (source of truth)

## Still needed from Vineeth
- [ ] Real AdMob App ID + 3 ad-unit IDs (banner, interstitial, rewarded)
- [ ] Support email address (privacy policy currently has `stride-support@example.com`)
- [ ] Public URL for the hosted privacy policy (currently a placeholder)
- [ ] Google Play developer account ($25 + ID verification)
- [ ] Decision: personal vs organization account type
