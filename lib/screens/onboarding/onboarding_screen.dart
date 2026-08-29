import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/app_colors.dart';

/// Onboarding/Welcome screen matching design-reference/onboarding_welcome/code.html.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Welcome to Weasly',
      subtitle: 'Your friendly companion for stashing away savings and tracking every peso.',
      icon: Icons.savings_rounded,
    ),
    OnboardingItem(
      title: 'Track Every Stash',
      subtitle: 'Organize Cash, GCash, Bank accounts, and custom stashes all in one clean dashboard.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    OnboardingItem(
      title: 'Budget & Save Smart',
      subtitle: 'Set spending limits, stay ahead of recurring bills, and reach your savings goals with ease.',
      icon: Icons.pie_chart_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinishOnboarding() {
    ref.read(onboardingControllerProvider.notifier).completeOnboarding();
  }

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onFinishOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),

            // Top Image / Mascot Illustration Container
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Glow Circle
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      // Mascot Image Container
                      Container(
                        width: 220,
                        height: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.borderDefault, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/WeaslyLogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _items[_currentPage].icon,
                            size: 80,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Content Card Sheet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 32.0),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PageView for Titles & Subtitles
                  SizedBox(
                    height: 120,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Column(
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentPrimary,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pagination Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.accentPrimary
                              : AppColors.borderDefault,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
