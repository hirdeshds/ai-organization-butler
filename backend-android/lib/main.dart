import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'core/services/storage_service.dart';

import 'features/main_navigation.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OrganizationButlerApp());
}

class OrganizationButlerApp extends StatelessWidget {
  const OrganizationButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        title: 'Organization Butler',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppInitializer(),
        routes: {
          '/main': (context) => const MainNavigation(),
        },
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isChecking = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final storage = StorageService();
    final isComplete = await storage.isOnboardingComplete();
    
    if (mounted) {
      setState(() {
        _needsOnboarding = !isComplete;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_needsOnboarding) {
      return const OnboardingScreen();
    }

    return const MainNavigation();
  }
}

// test commit
