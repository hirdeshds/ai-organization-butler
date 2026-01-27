import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _showCelebration = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  // ✅ Check if all tasks completed and navigate
  void _checkCompletion(List<CleanupTask> tasks, AppState appState) {
    if (_hasNavigated) return;

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;

    if (completedCount == totalCount && totalCount > 0) {
      _hasNavigated = true;
      setState(() => _showCelebration = true);
      _celebrationController.forward();

      // Update room status and navigate after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          final room = appState.currentRoom;
          if (room != null) {
            appState.updateRoom(room.copyWith(status: RoomStatus.cleaned));
          }

          Navigator.of(context).popUntil((route) => route.isFirst);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 12),
                  Text('🎉 Room cleaned! Great job!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final currentRoom = appState.currentRoom;

        // ✅ Get tasks for current room only
        final tasks = currentRoom != null
            ? appState.getTasksForRoom(currentRoom.id)
            : <CleanupTask>[];

        final completedCount = tasks.where((t) => t.isCompleted).length;
        final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

        // ✅ Check completion after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkCompletion(tasks, appState);
        });

        return Scaffold(
          backgroundColor: const Color(0xFF121216),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, currentRoom),
                  Expanded(
                    child: tasks.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildProgressSection(context, completedCount, tasks.length, progress),
                          const SizedBox(height: 24),
                          _buildTaskList(context, tasks, appState),
                          const SizedBox(height: 24),
                          _buildAITipCard(context, appState),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Celebration overlay
              if (_showCelebration) _buildCelebrationOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a room to generate cleanup tasks',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * _celebrationController.value),
          child: Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _celebrationController,
                curve: Curves.elasticOut,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  const Text(
                    'Room Cleaned!',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great job! Returning to dashboard...',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Room? room) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF121216).withOpacity(0.7),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFa65eed).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFa65eed), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Strategy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        room?.name.toUpperCase() ?? 'ORGANIZATION BUTLER',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                ),
                color: AppColors.cardDark,
                onSelected: (value) {},
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'reset', child: Text('Reset Tasks', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'share', child: Text('Share Progress', style: TextStyle(color: Colors.white))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, int completed, int total, double progress) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Refined Cleanup', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('$completed of $total tasks completed', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${(progress * 100).toInt()}',
                      style: TextStyle(
                        color: progress == 1.0 ? Colors.green : const Color(0xFFa65eed),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: TextStyle(
                        color: progress == 1.0 ? Colors.green : const Color(0xFFa65eed),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 8,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: progress == 1.0 ? Colors.green : const Color(0xFFa65eed),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: (progress == 1.0 ? Colors.green : const Color(0xFFa65eed)).withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          progress < 0.5
              ? 'Great start! Keep the momentum going.'
              : progress < 1.0
              ? 'Almost there! Your focus is peak.'
              : '🎉 All tasks completed!',
          style: TextStyle(
            color: progress == 1.0 ? Colors.green : AppColors.textTertiary.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context, List<CleanupTask> tasks, AppState appState) {
    final sortedTasks = [...tasks]..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.priority.compareTo(b.priority);
    });

    return Column(
      children: sortedTasks.map((task) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTaskCard(context, task, appState, tasks),
      )).toList(),
    );
  }

  Widget _buildTaskCard(BuildContext context, CleanupTask task, AppState appState, List<CleanupTask> tasks) {
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    final isActive = !task.isCompleted && incompleteTasks.isNotEmpty && incompleteTasks.first.id == task.id;

    return GestureDetector(
      onTap: () => appState.toggleTask(task.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? Colors.green.withOpacity(0.1)
              : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted
                ? Colors.green.withOpacity(0.3)
                : isActive
                ? const Color(0xFFa65eed).withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: task.isCompleted
                    ? const RadialGradient(colors: [Colors.green, Color(0xFF22AA44)])
                    : null,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.transparent
                      : isActive
                      ? const Color(0xFFa65eed).withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: task.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted ? Colors.white.withOpacity(0.5) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(task.description, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFa65eed).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${task.durationMinutes} min',
                style: TextStyle(
                  color: isActive ? const Color(0xFFa65eed) : AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAITipCard(BuildContext context, AppState appState) {
    final tips = [
      "Studies show that a clear desk reduces cortisol levels by 15%. You're not just cleaning; you're optimizing your mental bandwidth.",
      "Try the 'one in, one out' rule: for every new item you bring in, remove one old item.",
      "The 20/20 rule: If you can replace something for under \$20 in under 20 minutes, you probably don't need to keep it.",
      "Cleaning in 15-minute bursts is more effective than marathon sessions.",
    ];

    final tip = tips[DateTime.now().minute % tips.length];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFa65eed).withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFa65eed).withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFa65eed).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFa65eed), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Butler's Insight", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(tip, style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}