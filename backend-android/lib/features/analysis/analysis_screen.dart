import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';
import '../strategy/strategy_screen.dart';

class AnalysisScreen extends StatefulWidget {
const AnalysisScreen({super.key});

@override
State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
late AnimationController _animController;
late Animation<double> _fadeAnimation;
int? _selectedItemIndex;

@override
void initState() {
super.initState();
_animController = AnimationController(
duration: const Duration(milliseconds: 800),
vsync: this,
);
_fadeAnimation = CurvedAnimation(
parent: _animController,
curve: Curves.easeOut,
);
_animController.forward();
}

@override
void dispose() {
_animController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Consumer<AppState>(
builder: (context, appState, _) {
final room = appState.currentRoom;

if (room == null) {
return Scaffold(
backgroundColor: AppColors.backgroundDark,
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.error_outline, color: Colors.white54, size: 64),
const SizedBox(height: 16),
const Text('No room selected', style: TextStyle(color: Colors.white, fontSize: 18)),
const SizedBox(height: 24),
ElevatedButton(
onPressed: () => Navigator.pop(context),
child: const Text('Go Back'),
),
],
),
),
);
}

return Scaffold(
backgroundColor: AppColors.backgroundDark,
body: Stack(
children: [
Positioned.fill(child: _buildRoomImageWithDetections(room, appState)),
Positioned.fill(
child: IgnorePointer(
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.black.withOpacity(0.3),
Colors.transparent,
AppColors.backgroundDark.withOpacity(0.8),
AppColors.backgroundDark,
],
stops: const [0.0, 0.2, 0.6, 1.0],
),
),
),
),
),
SafeArea(
child: Column(
children: [
_buildHeader(context, room),
const Spacer(),
if (_selectedItemIndex != null && _selectedItemIndex! < room.clutterItems.length)
_buildSelectedItemCard(room.clutterItems[_selectedItemIndex!]),
FadeTransition(
opacity: _fadeAnimation,
child: _buildAnalysisCard(context, room, appState),
),
],
),
),
],
),
);
},
);
}

Widget _buildRoomImageWithDetections(Room room, AppState appState) {
return LayoutBuilder(
builder: (context, constraints) {
final screenWidth = constraints.maxWidth;
final screenHeight = constraints.maxHeight;

return Stack(
fit: StackFit.expand,
children: [
_buildImage(room, appState),
...room.clutterItems.asMap().entries.map((entry) {
final index = entry.key;
final item = entry.value;
return _buildDetectionBox(
item: item,
index: index,
screenWidth: screenWidth,
screenHeight: screenHeight,
isSelected: _selectedItemIndex == index,
);
}),
],
);
},
);
}

Widget _buildImage(Room room, AppState appState) {
// Check if we have a selected image file (from camera/gallery)
if (appState.selectedImage != null && appState.selectedImage!.existsSync()) {
return Image.file(
appState.selectedImage!,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => _buildImageError(),
);
}

// Check if imageUrl is a local file path
if (room.imageUrl.startsWith('/') || room.imageUrl.startsWith('file://')) {
final file = File(room.imageUrl.replaceFirst('file://', ''));
if (file.existsSync()) {
return Image.file(
file,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => _buildImageError(),
);
}
}

// Try loading as network image
if (room.imageUrl.startsWith('http')) {
return Image.network(
room.imageUrl,
fit: BoxFit.cover,
loadingBuilder: (context, child, loadingProgress) {
if (loadingProgress == null) return child;
return Container(
color: AppColors.cardDark,
child: Center(
child: CircularProgressIndicator(
value: loadingProgress.expectedTotalBytes != null
? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
    : null,
color: AppColors.primary,
),
),
);
},
errorBuilder: (_, __, ___) => _buildImageError(),
);
}

// Fallback - show error
return _buildImageError();
}

Widget _buildImageError() {
return Container(
color: AppColors.cardDark,
child: const Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.broken_image, size: 64, color: Colors.white24),
SizedBox(height: 8),
Text('Failed to load image', style: TextStyle(color: Colors.white38)),
],
),
);
}

Widget _buildDetectionBox({
required ClutterItem item,
required int index,
required double screenWidth,
required double screenHeight,
required bool isSelected,
}) {
final left = item.boundingBox.left * screenWidth;
final top = item.boundingBox.top * screenHeight;
final width = item.boundingBox.width * screenWidth;
final height = item.boundingBox.height * screenHeight;
final color = _getActionColor(item.suggestedAction);

return Positioned(
left: left.clamp(0, screenWidth - 50),
top: top.clamp(0, screenHeight - 30),
child: GestureDetector(
onTap: () => setState(() => _selectedItemIndex = _selectedItemIndex == index ? null : index),
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: width.clamp(60, screenWidth * 0.5),
height: height.clamp(40, screenHeight * 0.3),
decoration: BoxDecoration(
border: Border.all(color: isSelected ? Colors.white : color, width: isSelected ? 3 : 2),
borderRadius: BorderRadius.circular(8),
color: color.withOpacity(isSelected ? 0.3 : 0.1),
),
),
const SizedBox(height: 4),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: isSelected ? Colors.white : color.withOpacity(0.9),
borderRadius: BorderRadius.circular(4),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(_getActionIcon(item.suggestedAction), size: 12, color: isSelected ? color : Colors.white),
const SizedBox(width: 4),
Text(item.label, style: TextStyle(color: isSelected ? color : Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
],
),
),
],
),
),
),
);
}

Widget _buildSelectedItemCard(ClutterItem item) {
final color = _getActionColor(item.suggestedAction);
return Container(
margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppColors.cardDark,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: color.withOpacity(0.5)),
),
child: Row(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
child: Icon(_getActionIcon(item.suggestedAction), color: color, size: 24),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
const SizedBox(height: 4),
Text('Suggested: ${item.suggestedAction.label}', style: TextStyle(color: color, fontSize: 13)),
],
),
),
IconButton(onPressed: () => setState(() => _selectedItemIndex = null), icon: const Icon(Icons.close, color: Colors.white54)),
],
),
);
}

Color _getActionColor(ClutterAction action) {
switch (action) {
case ClutterAction.discard: return AppColors.softRose;
case ClutterAction.relocate: return AppColors.electricTeal;
case ClutterAction.donate: return AppColors.primary;
case ClutterAction.keep: return AppColors.neonLime;
}
}

IconData _getActionIcon(ClutterAction action) {
switch (action) {
case ClutterAction.discard: return Icons.delete_outline;
case ClutterAction.relocate: return Icons.move_to_inbox;
case ClutterAction.donate: return Icons.card_giftcard;
case ClutterAction.keep: return Icons.check_circle_outline;
}
}

Widget _buildHeader(BuildContext context, Room room) {
return Padding(
padding: const EdgeInsets.all(16),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.4),
shape: BoxShape.circle,
border: Border.all(color: Colors.white.withOpacity(0.1)),
),
child: const Icon(Icons.arrow_back, color: Colors.white),
),
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.4),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: Colors.white.withOpacity(0.1)),
),
child: Row(
children: [
Container(
width: 8, height: 8,
decoration: BoxDecoration(
color: room.status == RoomStatus.analyzed ? AppColors.neonLime : AppColors.primary,
shape: BoxShape.circle,
boxShadow: [BoxShadow(color: (room.status == RoomStatus.analyzed ? AppColors.neonLime : AppColors.primary).withOpacity(0.5), blurRadius: 6)],
),
),
const SizedBox(width: 8),
Text(room.status == RoomStatus.analyzed ? 'ANALYZED' : 'CLEANED', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
],
),
),
GestureDetector(
onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon!'))),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
child: const Icon(Icons.share, color: Colors.white, size: 20),
),
),
],
),
);
}

Widget _buildAnalysisCard(BuildContext context, Room room, AppState appState) {
return Container(
margin: const EdgeInsets.all(16),
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: AppColors.cardDark,
borderRadius: BorderRadius.circular(24),
border: Border.all(color: Colors.white.withOpacity(0.1)),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5))],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(room.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
const SizedBox(height: 4),
Row(
children: [
Icon(Icons.view_in_ar, size: 14, color: AppColors.primary.withOpacity(0.8)),
const SizedBox(width: 4),
Text('${room.clutterItems.length} items detected', style: const TextStyle(color: AppColors.textTertiary, fontSize: 14)),
],
),
],
),
),
const SizedBox(width: 16),
_buildScoreCircle(room.clutterScore),
],
),
const SizedBox(height: 24),
Row(
children: [
_buildBreakdownItem('Discard', room.clutterItems.where((i) => i.suggestedAction == ClutterAction.discard).length, AppColors.softRose, Icons.delete_outline),
_buildBreakdownItem('Relocate', room.clutterItems.where((i) => i.suggestedAction == ClutterAction.relocate).length, AppColors.electricTeal, Icons.move_to_inbox),
_buildBreakdownItem('Keep', room.clutterItems.where((i) => i.suggestedAction == ClutterAction.keep).length, AppColors.neonLime, Icons.check_circle_outline),
_buildBreakdownItem('Donate', room.clutterItems.where((i) => i.suggestedAction == ClutterAction.donate).length, AppColors.primary, Icons.card_giftcard),
],
),
const SizedBox(height: 24),
GestureDetector(
onTap: () {
final existingTasks = appState.getTasksForRoom(room.id);
if (existingTasks.isEmpty) {
appState.generateTasksForRoom(room.id);
}
// ✅ FIX: Pass roomId to StrategyScreen

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const StrategyScreen(),
),
);
},
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 16),
decoration: BoxDecoration(
gradient: AppColors.primaryGradient,
borderRadius: BorderRadius.circular(12),
boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
),
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.play_arrow, color: Colors.white),
SizedBox(width: 8),
Text('Start Cleanup Strategy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
],
),
),
),
],
),
);
}

Widget _buildScoreCircle(int score) {
final color = score < 30 ? AppColors.neonLime : score < 70 ? Colors.orange : AppColors.softRose;
final label = score < 30 ? 'Great!' : score < 70 ? 'Moderate' : 'Cluttered';

return TweenAnimationBuilder<double>(
tween: Tween(begin: 0, end: score.toDouble()),
duration: const Duration(milliseconds: 1000),
curve: Curves.easeOutCubic,
builder: (context, value, child) {
return Container(
width: 80, height: 80,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: color.withOpacity(0.3), width: 4),
gradient: RadialGradient(colors: [color.withOpacity(0.1), Colors.transparent]),
),
child: Stack(
alignment: Alignment.center,
children: [
SizedBox(width: 72, height: 72, child: CircularProgressIndicator(value: value / 100, strokeWidth: 4, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(color))),
Column(
mainAxisSize: MainAxisSize.min,
children: [
Text('${value.toInt()}', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 8, fontWeight: FontWeight.w600)),
],
),
],
),
);
},
);
}

Widget _buildBreakdownItem(String label, int count, Color color, IconData icon) {
return Expanded(
child: Container(
margin: const EdgeInsets.symmetric(horizontal: 4),
padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
child: Column(
children: [
Icon(icon, color: color, size: 18),
const SizedBox(height: 4),
Text('$count', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
],
),
),
);
}
}