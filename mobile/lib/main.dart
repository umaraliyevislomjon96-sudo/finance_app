import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/main_bottom_nav.dart';
import 'features/auth/registration_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AuroraFinanceApp(startWithOnboarding: false));
}

class AuroraFinanceApp extends StatelessWidget {
  final bool startWithOnboarding;

  const AuroraFinanceApp({super.key, this.startWithOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Aurora Finance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          initialRoute: startWithOnboarding ? '/onboarding' : '/dashboard',
          routes: {
            '/onboarding': (context) => const RegistrationScreen(),
            '/dashboard': (context) => const MainBottomNav(),
          },
        );
      },
    );
  }
}
