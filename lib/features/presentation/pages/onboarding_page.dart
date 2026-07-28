import 'package:flutter/material.dart';

/// First-launch onboarding with swipeable walkthrough slides.
///
/// Explains: Detect → Measure → Export workflow.
/// Shows once, then persists via callback.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.sensors_rounded,
      title: 'Smart Detection',
      subtitle: 'Automatically detects your device\u2019s sensors \u2014 '
          'LiDAR, depth camera, ARCore, GPS, and more \u2014 '
          'then selects the best measurement engine.',
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    _Slide(
      icon: Icons.straighten_rounded,
      title: 'Measure Anything',
      subtitle: 'Rooms, buildings, land plots, objects \u2014 '
          'measure in seconds with camera, GPS, or manual input. '
          '27+ shape types with professional accuracy.',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _Slide(
      icon: Icons.camera_alt_rounded,
      title: 'Camera-First Workflow',
      subtitle: 'Capture a photo, add dimension annotations, '
          'and instantly calculate area, volume, and material estimates. '
          'No engineering experience needed.',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    _Slide(
      icon: Icons.picture_as_pdf_rounded,
      title: 'Export & Share',
      subtitle: 'Generate PDF reports, DXF floor plans, '
          'GeoJSON maps, CSV data, and more. '
          'Share with clients, contractors, and teams.',
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _buildSlide(_slides[i], theme),
              ),
            ),
            // Indicators + button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Get Started button
                  FilledButton.icon(
                    onPressed: () {
                      if (_currentPage == _slides.length - 1) {
                        widget.onComplete();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
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

  Widget _buildSlide(_Slide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient icon circle
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            slide.subtitle,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
