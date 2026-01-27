import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  String _selectedEmoji = '👤';

  final List<String> _emojiOptions = [
    '👤', '😊', '🎯', '✨', '🌟', '🚀',
    '🎨', '💼', '🏠', '🌱', '🔥', '💪',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
    }
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.completeOnboarding(
      _nameController.text.trim(),
      _selectedEmoji,
    );
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              Row(
                children: List.generate(2, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              // Content
              Expanded(
                child: _currentStep == 0 ? _buildNameStep() : _buildEmojiStep(),
              ),
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to\nOrganization Butler',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Let\'s personalize your experience. What should we call you?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your\nprofile emoji',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pick an emoji that represents you. You can change this later.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 48),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _emojiOptions.length,
            itemBuilder: (context, index) {
              final emoji = _emojiOptions[index];
              final isSelected = emoji == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep == 0 ? 1 : 1,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == 0 ? 'Continue' : 'Get Started',
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
