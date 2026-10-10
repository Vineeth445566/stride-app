import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';

/// Banner ad pinned to the bottom of a tab. Collapses to nothing while loading.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsService>();
    final ad = ads.bannerAd;
    if (!ads.bannerReady || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
