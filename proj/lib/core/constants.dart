/// Test ad unit IDs from Google. They always return test ads.
///
/// ⚠️ BEFORE MONETIZING: create a free AdMob account
/// (https://admob.google.com), create 3 ad units (Banner, Interstitial,
/// Rewarded) for this app, and replace the IDs below with your real ones.
/// The matching AdMob APP ID goes in AndroidManifest.xml
/// (com.google.android.gms.ads.APPLICATION_ID).
/// Then set [AdConfig.adsEnabled] to true.
class AdIds {
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Test App ID for AndroidManifest.xml
  static const appId = 'ca-app-pub-3940256099942544~3347511713';
}

/// Master switch for AdMob monetization.
///
/// - `false` (default for v1.0.0): no ads are loaded or shown; all themes are
///   free. Ship the app like this and enable ads in a later update once real
///   AdMob IDs are configured.
/// - `true`: banner, interstitial, and rewarded ads are active; locked themes
///   require watching a rewarded ad. Requires real ad-unit IDs in [AdIds].
class AdConfig {
  static const adsEnabled = false;
}

/// Filled in when the store listing is ready.
class Links {
  // Hosted privacy policy URL (required by Play Console).
  static const privacyPolicy = 'https://example.com/stride-privacy';
  // Play Store URL of this app (for the in-app "Rate us" button).
  static const playStore = 'https://play.google.com/store/apps/details?id=app.stride.stepcounter';
}
