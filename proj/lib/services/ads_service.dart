import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// AdMob monetization (gated by [AdConfig.adsEnabled]):
/// - Banner ad pinned to the bottom of the Home and History tabs.
/// - Interstitial shown when opening History, at most once every 3 minutes.
/// - Rewarded ad that unlocks premium color themes (opt-in only).
///
/// When [AdConfig.adsEnabled] is false, [init] is a no-op: no ads load, the
/// banner widget renders nothing, interstitials never show, and locked themes
/// are free (see settings_screen.dart).
///
/// All unit IDs are Google's official TEST IDs. Swap in real AdMob IDs
/// (see core/constants.dart) and set [AdConfig.adsEnabled] = true before
/// monetizing.
class AdsService extends ChangeNotifier {
  BannerAd? bannerAd;
  bool bannerReady = false;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  DateTime? _lastInterstitial;

  Future<void> init() async {
    if (!AdConfig.adsEnabled) return;
    _loadBanner();
    _loadInterstitial();
    _loadRewarded();
  }

  // ---------- banner ----------
  void _loadBanner() {
    bannerAd = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          bannerReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  // ---------- interstitial ----------
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Shows an interstitial if one is loaded and the 3-minute cooldown passed.
  /// No-op when ads are disabled.
  void maybeShowInterstitial() {
    if (!AdConfig.adsEnabled) return;
    final now = DateTime.now();
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!) < const Duration(minutes: 3)) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) return;
    _lastInterstitial = now;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // ---------- rewarded ----------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Returns true when the user watched the ad to completion.
  /// Returns false immediately when ads are disabled.
  Future<bool> showRewarded() async {
    if (!AdConfig.adsEnabled) return false;
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    var earned = false;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (a, reward) => earned = true);
    return done.future;
  }
}
