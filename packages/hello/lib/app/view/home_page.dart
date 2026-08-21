import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The panel shown at `/main` once someone is signed in.
///
/// This is a worked example, not a destination: it says so on screen, because
/// a generated app whose first signed-in screen reads "App is running" tells
/// the developer nothing about what to do next.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimensions = DimensionExtension.of(context);

    return Scaffold(
      // The backdrop paints the ground; a second opaque colour here would
      // cover it.
      backgroundColor: Colors.transparent,
      body: AmbientBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A ring rather than a filled disc: the check is the
                  // message, and a solid block of primary would outshout it.
                  Container(
                    padding: EdgeInsets.all(dimensions.space16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: AppIcon(
                      AppIcons.check,
                      size: dimensions.space32,
                      color: colorScheme.primary,
                      semanticLabel: 'Signed in',
                    ),
                  ),
                  SizedBox(height: dimensions.space24),
                  Text(
                    "You're in.",
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: dimensions.space12),
                  Text(
                    'This is where your app begins. Replace this page with '
                    'your first signed-in screen.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: dimensions.space32),
                  PillButton(
                    label: 'Start over',
                    // No session to end, so returning to the start of the
                    // flow is what signing out looks like in a scaffold.
                    //
                    // The path, not a typed route: every typed route for the
                    // start of the flow lives in features/onboarding/, and
                    // naming one here would make this page import the feature.
                    onPressed: () => GoRouter.of(context).go('/landing'),
                    theme: PillButtonThemeData.fallback(
                      context,
                      variant: PillButtonVariant.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
