import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'screens/main_screen.dart';
import 'services/ads_service.dart';
import 'services/step_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  final steps = StepService();
  await steps.init();

  final ads = AdsService();
  await ads.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: steps),
        ChangeNotifierProvider.value(value: ads),
      ],
      child: const StrideApp(),
    ),
  );
}

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepService>();
    return MaterialApp(
      title: 'Stride Step Counter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(steps.themeId),
      home: const MainScreen(),
    );
  }
}
