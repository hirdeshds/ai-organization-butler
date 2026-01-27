import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../analysis/analysis_screen.dart';

class ScanRoomScreen extends StatefulWidget {
  const ScanRoomScreen({super.key});

  @override
  State<ScanRoomScreen> createState() => _ScanRoomScreenState();
}

class _ScanRoomScreenState extends State<ScanRoomScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        // User cancelled
        return;
      }

      setState(() => _isProcessing = true);

      final appState = Provider.of<AppState>(context, listen: false);
      
      final success = await appState.analyzeRoomWithAPI(image.path);
      
      if (mounted) {
        setState(() => _isProcessing = false);
        
        if (success) {
          // Success - navigate to analysis screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AnalysisScreen(),
            ),
          );
        } else {
          // Error during analysis
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to analyze room. Please try again.'),
              backgroundColor: AppColors.softRose,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Error picking image
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.softRose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Scan Your Space',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Capture or upload a photo of your room to get AI-powered organization insights and personalized cleanup recommendations.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Action Cards
                  _buildActionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take Photo',
                    subtitle: 'Use your camera to capture the room',
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.deepLavender],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildActionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Upload from Gallery',
                    subtitle: 'Select an existing photo from your device',
                    gradient: LinearGradient(
                      colors: [
                        AppColors.electricTeal,
                        AppColors.teal,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Tips section
                  _buildTipsSection(),
                ],
              ),
            ),
          ),
          
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing your room...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.neonLime,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tips for Best Results',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Ensure good lighting for better object detection'),
          const SizedBox(height: 8),
          _buildTipItem('Capture the entire room from a wide angle'),
          const SizedBox(height: 8),
          _buildTipItem('Keep the camera steady for clearer images'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 12),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.neonLime,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
