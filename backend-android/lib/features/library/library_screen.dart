import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/models.dart';
import '../analysis/analysis_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Recent', 'Spotless'];
  String _searchQuery = '';
  bool _isSearching = false;

  List<Room> _getFilteredRooms(List<Room> rooms) {
    var filtered = rooms;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_selectedFilter) {
      case 1:
        filtered = filtered.where((r) =>
        r.completedAt != null &&
            r.completedAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ).toList();
        break;
      case 2:
        filtered = filtered.where((r) => r.isSpotless).toList();
        break;
    }

    filtered.sort((a, b) => (b.completedAt ?? DateTime(2000)).compareTo(a.completedAt ?? DateTime(2000)));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _){
        final rooms = _getFilteredRooms(appState.rooms);

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildFilterTabs(),
                Expanded(
                  child: rooms.isEmpty
                      ? _buildEmptyState(context)
                      : _buildRoomGrid(context, rooms, appState),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (!_isSearching) ...[
            const Expanded(
              child: Text(
                'Archived Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isSearching = true),
              child: const Icon(Icons.search, color: Colors.white, size: 24),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272a),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search rooms...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.white54, size: 20),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() {
                _isSearching = false;
                _searchQuery = '';
              }),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF27272a),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: _filters.asMap().entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3f3f46) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomGrid(BuildContext context, List<Room> rooms, AppState appState) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) => _buildRoomCard(context, rooms[index], appState),
    );
  }

  // ✅ FIXED: Image loading helper method
  Widget _buildRoomImage(Room room) {
    // Check if imageUrl is a local file path
    if (room.imageUrl.startsWith('/') || room.imageUrl.startsWith('file://')) {
      final filePath = room.imageUrl.replaceFirst('file://', '');
      final file = File(filePath);

      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }

    // Network image (http/https)
    if (room.imageUrl.startsWith('http')) {
      return Image.network(
        room.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }

    // Fallback placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.cardDark,
      child: const Center(
        child: Icon(Icons.home, color: Colors.white24, size: 48),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room, AppState appState) {
    return GestureDetector(
      onTap: () {
        appState.selectRoom(room.id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnalysisScreen()),
        );
      },
      onLongPress: () => _showRoomOptions(context, room, appState),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // ✅ FIXED: Use helper method instead of Image.network
                    child: _buildRoomImage(room),
                  ),
                ),
                // Status indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: room.isSpotless ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                // Score badge - More visible
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(room.clutterScore),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${room.clutterScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  room.completedAt != null
                      ? 'Completed ${_formatDate(room.completedAt!)}'
                      : 'Last scanned ${_formatDate(room.lastScanned ?? DateTime.now())}',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.grid_view,
              size: 56,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No rooms found' : 'Your space, archived',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Old sessions move here once\nthe room is spotless.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to scan
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3d8a89).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Scan New Room',
                style: TextStyle(
                  color: Color(0xFF3d8a89),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomOptions(BuildContext context, Room room, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(room.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            _OptionItem(
              icon: Icons.analytics,
              label: 'View Analysis',
              onTap: () {
                Navigator.pop(context);
                appState.selectRoom(room.id);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalysisScreen()));
              },
            ),
            _OptionItem(
              icon: Icons.refresh,
              label: 'Rescan Room',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to processing
              },
            ),
            _OptionItem(
              icon: Icons.share,
              label: 'Share Progress',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for score color
  Color _getScoreColor(int score) {
    if (score < 30) return Colors.green;
    if (score < 70) return Colors.orange;
    return Colors.redAccent;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}