import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const primaryTeal = Color(0xFF17b0cf);
  static const neonLime = Color(0xFFbef264);
  static const electricLavender = Color(0xFFa78bfa);
  static const softRose = Color(0xFFF43F5E);
  static const surfaceDark = Color(0xFF1f1f26);
  static const borderDark = Color(0xFF2d2d34);

  // Helper method to format TimeOfDay without context
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF17171c),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileSection(context, appState),
                  _buildAIConfigSection(context, appState),
                  _buildPreferencesSection(context, appState),
                  _buildStatsSection(context, appState),
                  _buildSystemSection(context),
                  _buildLogoutButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(BuildContext context, AppState appState) {
    final user = appState.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _showEditProfileSheet(context, appState),
                child: Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryTeal.withOpacity(0.2), width: 2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context, appState),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF17171c), width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ),
              // Premium badge
              if (user.isPremium)
                Positioned(
                  bottom: -4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: neonLime,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: neonLime.withOpacity(0.2), blurRadius: 12)],
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          if (user.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildAIConfigSection(BuildContext context, AppState appState) {
    final settings = appState.settings;
    return _buildSection(
      title: 'AI CONFIGURATION',
      children: [
        _buildListItem(
          icon: Icons.smart_toy,
          iconBgColor: primaryTeal.withOpacity(0.1),
          iconColor: primaryTeal,
          title: 'AI Personality',
          subtitle: settings.aiPersonality,
          onTap: () => _showPersonalityPicker(context, appState),
        ),
        _buildDivider(),
        _buildListItem(
          icon: Icons.schedule,
          iconBgColor: primaryTeal.withOpacity(0.1),
          iconColor: primaryTeal,
          title: 'Decluttering Frequency',
          subtitle: '${settings.scanFrequency} Smart Scan at ${_formatTimeOfDay(settings.scheduledScanTime)}',
          onTap: () => _showFrequencyPicker(context, appState),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, AppState appState) {
    final settings = appState.settings;
    return _buildSection(
      title: 'PREFERENCES',
      children: [
        _buildListItem(
          icon: Icons.dark_mode,
          iconBgColor: Colors.grey[800]!,
          iconColor: Colors.grey[300]!,
          title: 'Theme',
          subtitle: settings.darkModeEnabled ? 'Always Dark Mode' : 'Light Mode',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dark mode is currently the only available theme')),
            );
          },
        ),
        _buildDivider(),
        _buildListItem(
          icon: Icons.notifications,
          iconBgColor: Colors.grey[800]!,
          iconColor: Colors.grey[300]!,
          title: 'Notifications',
          subtitle: settings.notificationsEnabled ? 'Active Status Alerts' : 'Disabled',
          trailing: _buildToggle(settings.notificationsEnabled, () => appState.toggleNotifications()),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, AppState appState) {
    final user = appState.user;
    final hasStats = user.totalItemsSorted > 0 || user.streakDays > 0 || appState.cleanedRooms.isNotEmpty;
    
    return _buildSection(
      title: 'YOUR STATS',
      children: [
        hasStats ? Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatItem(icon: Icons.inventory_2, value: '${user.totalItemsSorted}', label: 'Items Sorted'),
              _StatItem(icon: Icons.local_fire_department, value: '${user.streakDays}', label: 'Day Streak'),
              _StatItem(icon: Icons.home, value: '${appState.cleanedRooms.length}', label: 'Rooms Cleaned'),
            ],
          ),
        ) : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.bar_chart_outlined, color: Colors.grey[600], size: 32),
              const SizedBox(height: 12),
              Text(
                'No stats yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Your statistics will appear here',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    return _buildSection(
      title: 'SYSTEM',
      children: [
        _buildListItem(
          icon: Icons.shield,
          iconBgColor: Colors.grey[800]!,
          iconColor: Colors.grey[300]!,
          title: 'Privacy Policy',
          trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
          onTap: () => _showComingSoon(context),
        ),
        _buildDivider(),
        _buildListItem(
          icon: Icons.description,
          iconBgColor: Colors.grey[800]!,
          iconColor: Colors.grey[300]!,
          title: 'Terms of Service',
          trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
          onTap: () => _showComingSoon(context),
        ),
        _buildDivider(),
        _buildListItem(
          icon: Icons.help_outline,
          iconBgColor: Colors.grey[800]!,
          iconColor: Colors.grey[300]!,
          title: 'Help & Support',
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderDark),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: borderDark));

  Widget _buildToggle(bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(color: value ? electricLavender : Colors.grey[700], borderRadius: BorderRadius.circular(12)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20, height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showLogoutConfirmation(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: softRose.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: softRose.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: softRose, size: 20),
                  const SizedBox(width: 8),
                  Text('Logout from System', style: TextStyle(color: softRose, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('ORGANIZATION BUTLER V2.4.1 (PREMIUM EARLY ACCESS)', style: TextStyle(color: Colors.grey[700], fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AppState appState) {
    final nameController = TextEditingController(text: appState.user.name);
    String selectedEmoji = appState.user.emoji;
    
    final emojiOptions = [
      '👤', '😊', '🎯', '✨', '🌟', '🚀',
      '🎨', '💼', '🏠', '🌱', '🔥', '💪',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _buildTextField('Name', nameController),
              const SizedBox(height: 24),
              const Text('Profile Emoji', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojiOptions.map((emoji) {
                  final isSelected = emoji == selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => selectedEmoji = emoji),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryTeal.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryTeal : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  appState.updateUser(appState.user.copyWith(
                    name: nameController.text,
                    emoji: selectedEmoji,
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF17171c), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderDark)),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  void _showPersonalityPicker(BuildContext context, AppState appState) {
    final personalities = ['Sophisticated Butler', 'Friendly Coach', 'Minimalist Mentor', 'Strict Organizer'];
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Personality', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...personalities.map((p) => GestureDetector(
              onTap: () {
                appState.setAIPersonality(p);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(appState.settings.aiPersonality == p ? Icons.radio_button_checked : Icons.radio_button_off, color: primaryTeal),
                    const SizedBox(width: 12),
                    Text(p, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showFrequencyPicker(BuildContext context, AppState appState) {
    final frequencies = ['Daily', 'Weekly', 'Bi-weekly', 'Monthly'];
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan Frequency', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...frequencies.map((f) => GestureDetector(
              onTap: () {
                appState.setScanFrequency(f);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(appState.settings.scanFrequency == f ? Icons.radio_button_checked : Icons.radio_button_off, color: primaryTeal),
                    const SizedBox(width: 12),
                    Text(f, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
            },
            child: Text('Logout', style: TextStyle(color: softRose)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF17b0cf), size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}