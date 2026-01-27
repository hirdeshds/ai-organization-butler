import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../analysis/analysis_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false; // ✅ ADD: Prevent multiple calls

  final List<String> _steps = [
    'Initializing AI Vision...',
    'Scanning room layout...',
    'Detecting objects...',
    'Analyzing clutter patterns...',
    'Generating cleanup plan...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ✅ FIX: Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  void _startProcessing() async {
    // ✅ FIX: Prevent multiple calls
    if (!mounted || _isProcessing) return;
    _isProcessing = true;

    final appState = Provider.of<AppState>(context, listen: false);

    // Listen to progress and update steps
    appState.addListener(_onProgressUpdate);

    // Start analysis using the selected image
    final success = await appState.analyzeRoomWithAPI(null);

    if (!mounted) return;

    appState.removeListener(_onProgressUpdate);

    if (success) {
      // Navigate to analysis screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      );
    } else {
      setState(() {
        _hasError = true;
        _isProcessing = false; // ✅ Reset for retry
        _errorMessage = appState.analysisError ?? 'Something went wrong';
      });
    }
  }

  void _onProgressUpdate() {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final progress = appState.analysisProgress;

    // Map progress to steps
    final newStep = (progress * (_steps.length - 1)).floor();
    if (newStep != _currentStep && newStep < _steps.length) {
      setState(() {
        _currentStep = newStep;
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _currentStep = 0;
      _isProcessing = false; // ✅ Reset flag
    });
    _startProcessing();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _hasError ? _buildErrorState() : _buildProcessingState(),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        // Header with close button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.resetAnalysis();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Animated scanner visualization
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * pi,
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.view_in_ar,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 48),

        // Current step text
        Text(
          _steps[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 24),

        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index <= _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Progress percentage
        Consumer<AppState>(
          builder: (context, appState, _) {
            return Text(
              '${(appState.analysisProgress * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),

        const Spacer(),

        // Tip card
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonLime.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb, color: AppColors.neonLime, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pro tip: Good lighting helps detect objects better! 💡',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _errorMessage ?? 'Failed to analyze your room',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Retry button
            GestureDetector(
              onTap: _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),


            TextButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.resetAnalysis();
                Navigator.pop(context);
              },
              child: Text(
                'Go Back',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}