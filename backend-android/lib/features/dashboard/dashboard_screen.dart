import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';
import '../processing/processing_screen.dart';
import '../analysis/analysis_screen.dart';
import '../strategy/strategy_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ImagePicker _picker = ImagePicker();

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
                  _buildHeader(context, appState.user),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildPrimaryActionCard(context, appState),
                        const SizedBox(height: 24),
                        _buildStreakCard(context, appState),
                        const SizedBox(height: 24),
                        _buildInsightsSection(context, appState),
                        const SizedBox(height: 24),
                        _buildActiveTasksSection(context, appState),
                        const SizedBox(height: 24),
                        _buildRecentRoomsSection(context, appState),
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

  // ============ FIX 1: Header with Expanded to prevent overflow ============
  Widget _buildHeader(BuildContext context, UserProfile user) {
    final greeting = _getGreeting();
    final now = DateTime.now();
    final dateStr = '${_getDayName(now.weekday).toUpperCase()}, ${_getMonthName(now.month).toUpperCase()} ${now.day}, ${now.year}';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // LEFT SIDE - Greeting (Expanded to take remaining space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis, // Truncate if too long
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // RIGHT SIDE - Icons (fixed size, won't overflow)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconButton(
                icon: Icons.notifications_outlined,
                onTap: () => _showNotifications(context),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(user.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ FIX 2: Primary Card with Scan functionality ============
  Widget _buildPrimaryActionCard(BuildContext context, AppState appState) {
    final roomToOptimize = appState.rooms.where((r) => r.status == RoomStatus.analyzed).isNotEmpty
        ? appState.rooms.where((r) => r.status == RoomStatus.analyzed).reduce((a, b) => a.clutterScore > b.clutterScore ? a : b)
        : null;

    // Check if user has scanned image or analyzed room
    final hasScannedImage = appState.selectedImage != null;
    final hasAnalysis = roomToOptimize != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI VISION ACTIVE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasAnalysis
                                ? 'Check your\n${roomToOptimize.name.toLowerCase()} analysis'
                                : 'Ready to scan\nyour space?',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.view_in_ar, color: AppColors.softLavender, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Room preview - Show scanned image or placeholder
                GestureDetector(
                  onTap: hasAnalysis ? null : () => _showScanOptions(context, appState),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Show user's scanned image, room image, or placeholder
                          if (hasScannedImage)
                            Image.file(appState.selectedImage!, fit: BoxFit.cover)
                          else if (hasAnalysis)
                            Image.network(
                              roomToOptimize.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            )
                          else
                            _buildPlaceholderImage(),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                              ),
                            ),
                          ),
                          // Status badge
                          Positioned(
                            left: 16, bottom: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.neonLime,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: AppColors.neonLime.withOpacity(0.6), blurRadius: 8)],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasAnalysis ? 'Analysis ready' : 'Tap to scan your room',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Tap indicator for scanning
                          if (!hasAnalysis)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Primary action button
                GestureDetector(
                  onTap: () {
                    if (hasAnalysis) {
                      appState.selectRoom(roomToOptimize.id);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                      );
                    } else {
                      _showScanOptions(context, appState);
                    }
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: hasAnalysis
                          ? AppColors.primaryGradient
                          : const LinearGradient(colors: [AppColors.neonLime, Color(0xFF9FE000)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (hasAnalysis ? AppColors.deepLavender : AppColors.neonLime).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasAnalysis ? Icons.analytics_rounded : Icons.document_scanner_rounded,
                          color: AppColors.backgroundDark,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasAnalysis ? 'View Analysis' : 'Scan My Room ✨',
                          style: const TextStyle(
                            color: AppColors.backgroundDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Secondary "Scan New" button if analysis exists
                if (hasAnalysis) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showScanOptions(context, appState),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Scan New Room',
                            style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.cardDark,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              color: AppColors.primary.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No room scanned yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Scan Options Bottom Sheet ============
  void _showScanOptions(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan Your Space 📸',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s see what we\'re working with',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildScanOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take a Photo',
              subtitle: 'Snap your room right now',
              color: AppColors.neonLime,
              onTap: () => _pickImage(ImageSource.camera, appState),
            ),
            const SizedBox(height: 12),
            _buildScanOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Pick an existing photo',
              color: AppColors.primary,
              onTap: () => _pickImage(ImageSource.gallery, appState),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AppState appState) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        appState.setSelectedImage(File(image.path));

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProcessingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ============ Rest of the widgets (unchanged) ============

  Widget _buildStreakCard(BuildContext context, AppState appState) {
    final hasStreak = appState.user.streakDays > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: hasStreak ? _buildStreakContent(appState) : _buildEmptyStreakContent(),
        ),
      ),
    );
  }

  Widget _buildStreakContent(AppState appState) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.neonLime.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonLime.withOpacity(0.2)),
              ),
              child: const Icon(Icons.local_fire_department, color: AppColors.neonLime, size: 24),
            ),
            Positioned(
              top: -2, right: -2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: AppColors.neonLime,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardDark, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.neonLime.withOpacity(0.6), blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appState.user.streakDays} Day Streak',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                appState.user.streakDays >= 7 ? 'Consistent for ${appState.user.streakDays ~/ 7} week(s)!' : 'Keep organizing daily!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Text('STATS', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildEmptyStreakContent() {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(Icons.local_fire_department, color: Colors.white.withOpacity(0.3), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No streak yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Start organizing to build your streak!', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, AppState appState) {
    final insights = appState.todayInsights;
    final hasData = insights.isNotEmpty && appState.user.totalItemsSorted > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('DAILY INSIGHTS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 16),
        hasData ? Row(
          children: [
            Expanded(child: _InsightCard(icon: Icons.inventory_2, iconColor: AppColors.primary, label: 'Sorted', value: insights[0].value ?? '0', suffix: 'items')),
            const SizedBox(width: 16),
            Expanded(child: _InsightCard(icon: Icons.cleaning_services, iconColor: AppColors.neonLime, label: 'Clutter', value: insights[1].value ?? '0%', suffix: 'today')),
          ],
        ) : _buildEmptyInsightsCard(),
      ],
    );
  }

  Widget _buildEmptyInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, color: Colors.white.withOpacity(0.3), size: 32),
          const SizedBox(height: 12),
          Text('No data yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Scan your first room to see insights', style: TextStyle(color: AppColors.textTertiary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActiveTasksSection(BuildContext context, AppState appState) {
    final incompleteTasks = appState.tasks.where((t) => !t.isCompleted).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ACTIVE TASKS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            if (incompleteTasks.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StrategyScreen())),
                child: Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        incompleteTasks.isEmpty
            ? _buildEmptyTasksCard()
            : Column(children: incompleteTasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TaskCard(task: task, onTap: () => appState.toggleTask(task.id)),
        )).toList()),
      ],
    );
  }

  Widget _buildEmptyTasksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt_outlined, color: Colors.white.withOpacity(0.3), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No active tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Complete a room scan to get tasks', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoomsSection(BuildContext context, AppState appState) {
    final recentRooms = appState.cleanedRooms.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT SPACES', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        recentRooms.isEmpty
            ? _buildEmptyRoomsCard()
            : Column(children: recentRooms.map((room) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoomCard(room: room, onTap: () {
            appState.selectRoom(room.id);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
          }),
        )).toList()),
      ],
    );
  }

  Widget _buildEmptyRoomsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, color: Colors.white.withOpacity(0.3), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No rooms scanned yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Scan your first room to get started', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            _NotificationItem(icon: Icons.check_circle, color: AppColors.neonLime, title: 'Task Completed!', subtitle: 'You organized your desk', time: '2h ago'),
            _NotificationItem(icon: Icons.local_fire_department, color: Colors.orange, title: 'Streak Extended!', subtitle: '7 days consistent', time: '1d ago'),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDayName(int day) => ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day];
  String _getMonthName(int month) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month];
}

// ==================== REUSABLE WIDGETS ====================

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? suffix;
  const _InsightCard({required this.icon, required this.iconColor, required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              if (suffix != null) ...[const SizedBox(width: 4), Text(suffix!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))],
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CleanupTask task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: task.isCompleted ? AppColors.neonLime.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? AppColors.neonLime : Colors.transparent,
                border: Border.all(color: task.isCompleted ? AppColors.neonLime : AppColors.primary.withOpacity(0.5), width: 2),
              ),
              child: task.isCompleted ? const Icon(Icons.check, color: AppColors.backgroundDark, size: 16) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(color: task.isCompleted ? Colors.white.withOpacity(0.5) : Colors.white, fontSize: 14, fontWeight: FontWeight.w600, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                  Text(task.description, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Text('${task.durationMinutes} min', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 56, height: 56, child: Image.network(room.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceDark, child: const Icon(Icons.home, size: 24)))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: room.isSpotless ? Colors.green : Colors.orange, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(room.isSpotless ? 'Spotless' : 'Score: ${room.clutterScore}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  const _NotificationItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          Text(time, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}