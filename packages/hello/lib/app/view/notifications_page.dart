import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// The panel shown at `/notifications`, the middle tab of the signed-in
/// shell.
///
/// A placeholder empty state, not a list: it says so on screen, because a
/// generated tab that renders three fake rows invites someone to style the
/// fakes rather than replace them.
///
/// Shares `HomePage`'s composition — transparent [Scaffold] over
/// [AmbientBackdrop], one centred column — because the two are the same
/// kind of screen. Replace the column with a real list; keep the shell.
///
/// `HomePage` in backticks, not brackets: this file does not import it, and
/// a doc link resolves against *this file's* imports.
class NotificationsPage extends StatelessWidget {
  /// Creates the notifications page.
  const NotificationsPage({super.key});

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
                  // A ring rather than a filled disc, matching HomePage: the
                  // glyph is the message, and a solid block of primary would
                  // outshout it.
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
                      AppIcons.notifications,
                      size: dimensions.space32,
                      color: colorScheme.primary,
                      semanticLabel: 'Notifications',
                    ),
                  ),
                  SizedBox(height: dimensions.space24),
                  Text(
                    'Nothing yet.',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: dimensions.space12),
                  Text(
                    'Notifications will show up here. Replace this page '
                    'with your own list when you have something to put in '
                    'it.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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
