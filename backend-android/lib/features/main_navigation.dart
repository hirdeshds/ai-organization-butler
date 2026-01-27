import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'library/library_screen.dart';
import 'insights/insights_screen.dart';
import 'settings/settings_screen.dart';
import 'assistant_chat/assistant_chat_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LibraryScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openAIAssistant() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AssistantChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        onCenterTap: _openAIAssistant,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onCenterTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.archive_outlined,
                  activeIcon: Icons.archive,
                  label: 'Library',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                // Center AI Button
                GestureDetector(
                  onTap: onCenterTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.softLavender, AppColors.deepLavender],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                  ),
                ),
                _NavItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights,
                  label: 'Insights',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.deepLavender : Colors.white.withOpacity(0.4),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.deepLavender : Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}