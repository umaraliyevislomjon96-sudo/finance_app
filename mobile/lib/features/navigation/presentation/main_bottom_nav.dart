import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../calculators/presentation/calculators_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          onBack: () => Navigator.of(context).pop(),
          onOpenAi: () {
            Navigator.of(context).pop();
            _navigateTo(1);
          },
          onOpenCards: () {
            Navigator.of(context).pop();
            _navigateTo(3);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationController.instance;
    final theme = ThemeController.instance;

    final screens = [
      HomeDashboardScreen(
        onNavigateToAi: () => _navigateTo(1),
        onNavigateToBills: () => _navigateTo(3),
        onNavigateToProfile: () => _openProfile(context),
      ),
      AiAssistantScreen(
        onBack: () => _navigateTo(0),
      ),
      const CalculatorsScreen(),
      const PlaceholderScreen(title: 'Bills & Obligations'),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([loc, theme]),
      builder: (context, _) {
        final isDark = theme.isDarkMode;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _currentIndex == 0
              ? null
              : AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.cyanAccent),
                ),
                const SizedBox(width: 8),
                Text(
                  loc.t('app_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            actions: [
              // Language Selector Menu
              PopupMenuButton<AppLanguage>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.currentLanguage.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
                onSelected: (l) => loc.setLanguage(l),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: AppLanguage.ru, child: Text('Русский (RU)')),
                  const PopupMenuItem(value: AppLanguage.en, child: Text('English (EN)')),
                  const PopupMenuItem(value: AppLanguage.uz, child: Text('O\'zbekcha (UZ)')),
                ],
              ),
              // Day / Night Theme Switcher
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFACC15) : AppColors.primaryBlue,
                  size: 22,
                ),
                tooltip: isDark ? loc.t('theme_light') : loc.t('theme_dark'),
                onPressed: () => theme.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090E17).withOpacity(0.95) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.softBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_filled, loc.t('nav_home')),
                    _buildNavItem(1, Icons.auto_awesome_rounded, loc.t('nav_ai'), isAi: true),
                    _buildNavItem(2, Icons.calculate_rounded, loc.t('nav_calculators')),
                    _buildNavItem(3, Icons.receipt_long_rounded, loc.t('upcoming_bills')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isAi = false}) {
    final isSelected = _currentIndex == index;
    final isDark = ThemeController.instance.isDarkMode;

    return GestureDetector(
      onTap: () => _navigateTo(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAi && isSelected)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyanAccent.withOpacity(0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            )
          else
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
              size: 22,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? (isDark ? Colors.white : AppColors.primaryBlue) : (isDark ? AppColors.textMuted : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
      ),
    );
  }
}
