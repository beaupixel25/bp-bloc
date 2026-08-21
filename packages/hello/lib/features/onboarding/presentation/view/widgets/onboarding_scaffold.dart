import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// {@template onboarding_scaffold}
/// The chrome both onboarding forms share: an [AmbientBackdrop] ground, a
/// transparent bar carrying only a back button, a headline, an optional
/// subtitle, and then whatever the form puts under them.
///
/// The body scrolls: at large text scales the headline and subtitle alone
/// can exceed the viewport, and the sheet must grow and scroll rather than
/// truncate.
/// {@endtemplate}
class OnboardingScaffold extends StatelessWidget {
  /// {@macro onboarding_scaffold}
  const OnboardingScaffold({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.onBack,
  });

  /// The page headline.
  final String title;

  /// The paragraph under the headline. Omitted when null.
  final String? subtitle;

  /// The form itself: fields, messages, and the primary action.
  final Widget child;

  /// Invoked by the back button. Null hides it.
  final VoidCallback? onBack;

  /// Horizontal page padding at the reference canvas.
  static const double horizontalPadding = 26;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // The primary action can end up pinned near the bottom of the page,
      // so the keyboard must push it rather than paint over it.
      resizeToAvoidBottomInset: true,
      body: AmbientBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: onBack == null
                        ? const SizedBox.shrink()
                        : IconActionButton(
                            icon: AppIcons.chevronLeft,
                            semanticLabel: 'Go back',
                            onPressed: onBack,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            height: 34 / 28,
                            letterSpacing: -0.4,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              height: 24 / 15,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        child,
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
