import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildWeeklyChart(context, appState),
                        const SizedBox(height: 24),
                        _buildStatsGrid(context, appState),
                        const SizedBox(height: 24),
                        _buildAchievementsSection(context, appState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your organization journey',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, AppState appState) {
    final scores = appState.weeklyScores;
    final hasData = scores.isNotEmpty && scores.any((s) => s > 0);
    final maxScore = 100;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: hasData ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (appState.scoreChange != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: appState.scoreChange < 0
                        ? AppColors.neonLime.withOpacity(0.1)
                        : AppColors.softRose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        appState.scoreChange < 0 ? Icons.trending_down : Icons.trending_up,
                        color: appState.scoreChange < 0 ? AppColors.neonLime : AppColors.softRose,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${appState.scoreChange.abs()}%',
                        style: TextStyle(
                          color: appState.scoreChange < 0 ? AppColors.neonLime : AppColors.softRose,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final score = index < scores.length ? scores[index] : 0;
                final height = (score / maxScore) * 120;
                final isToday = index == 6;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      width: 32,
                      height: height > 0 ? height : 4,
                      decoration: BoxDecoration(
                        gradient: isToday && score > 0
                            ? AppColors.primaryGradient
                            : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(score > 0 ? 0.2 : 0.05),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: isToday ? AppColors.primary : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ) : _buildEmptyChart(),
    );
  }

  Widget _buildEmptyChart() {
    return Column(
      children: [
        const Text(
          'Weekly Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_outlined, color: Colors.white.withOpacity(0.3), size: 48),
                const SizedBox(height: 16),
                Text(
                  'No data yet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your progress will appear here over time',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppState appState) {
    final hasAnyData = appState.user.totalItemsSorted > 0 || 
                       appState.user.streakDays > 0 || 
                       appState.cleanedRooms.isNotEmpty ||
                       appState.unlockedAchievements.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATISTICS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        hasAnyData ? Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.inventory_2,
                    value: '${appState.user.totalItemsSorted}',
                    label: 'Items Sorted',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    value: '${appState.user.streakDays}',
                    label: 'Day Streak',
                    color: AppColors.neonLime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.home,
                    value: '${appState.cleanedRooms.length}',
                    label: 'Rooms Cleaned',
                    color: AppColors.electricTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emoji_events,
                    value: '${appState.unlockedAchievements.length}',
                    label: 'Achievements',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ) : _buildEmptyStatsCard(),
      ],
    );
  }

  Widget _buildEmptyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.white.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            'Your insights will improve as you use the app',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI adapts to your habits over time',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, AppState appState) {
    final achievements = appState.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${appState.unlockedAchievements.length}/${achievements.length}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...achievements.map((achievement) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAchievementCard(achievement),
        )),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked
              ? AppColors.neonLime.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? AppColors.neonLime.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForAchievement(achievement.iconName),
              color: achievement.isUnlocked ? AppColors.neonLime : AppColors.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    color: achievement.isUnlocked ? Colors.white : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                if (!achievement.isUnlocked) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.isUnlocked)
            const Icon(Icons.check_circle, color: AppColors.neonLime, size: 24),
        ],
      ),
    );
  }

  IconData _getIconForAchievement(String iconName) {
    switch (iconName) {
      case 'cleaning_services': return Icons.cleaning_services;
      case 'self_improvement': return Icons.self_improvement;
      case 'category': return Icons.category;
      case 'space_dashboard': return Icons.space_dashboard;
      case 'minimize': return Icons.minimize;
      case 'workspace_premium': return Icons.workspace_premium;
      default: return Icons.emoji_events;
    }
  }
}