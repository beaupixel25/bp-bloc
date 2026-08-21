import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hello/app/bloc/app_bloc.dart';
import 'package:hello/l10n/l10n.dart' show AppLocalizations;

/// The second tab of the signed-in shell: theme mode and language.
///
/// Applies changes immediately by driving the app-wide state holder — there
/// is no separate save step.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;

    void onThemeChanged(ThemeMode? mode) {
      if (mode != null) context.read<AppBloc>().add(AppThemeChanged(mode));
    }

    void onLocaleChanged(Locale? locale) {
      context.read<AppBloc>().add(AppLocaleChanged(locale));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dimensions = DimensionExtension.of(context);

    return Scaffold(
      // The backdrop paints the ground; a second opaque colour here would
      // cover it.
      backgroundColor: Colors.transparent,
      body: AmbientBackdrop(
        // The backdrop paints with a DecoratedBox, which is not a Material.
        // ListTile and its subclasses paint their background and ink splashes
        // on the nearest Material ancestor, so without this the tiles below
        // trip a framework assertion the first time this page renders — and
        // on a device their splashes would simply be invisible.
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(dimensions.space24),
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(dimensions.space12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: AppIcon(
                      AppIcons.settings,
                      size: dimensions.space24,
                      color: colorScheme.primary,
                      semanticLabel: 'Settings',
                    ),
                  ),
                  SizedBox(width: dimensions.space16),
                  Text('Settings', style: textTheme.headlineSmall),
                ],
              ),
              SizedBox(height: dimensions.space32),
              Text('Appearance', style: textTheme.titleMedium),
              SizedBox(height: dimensions.space8),
              RadioGroup<ThemeMode>(
                groupValue: state.themeMode,
                onChanged: onThemeChanged,
                child: Column(
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        title: Text(_themeModeLabel(mode)),
                      ),
                  ],
                ),
              ),
              SizedBox(height: dimensions.space32),
              Text('Language', style: textTheme.titleMedium),
              SizedBox(height: dimensions.space8),
              RadioGroup<Locale?>(
                groupValue: state.locale,
                onChanged: onLocaleChanged,
                child: Column(
                  children: [
                    const RadioListTile<Locale?>(
                      value: null,
                      title: Text('Follow device'),
                    ),
                    for (final locale in AppLocalizations.supportedLocales)
                      RadioListTile<Locale?>(
                        value: locale,
                        title: Text(locale.toLanguageTag().toUpperCase()),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// Display label for [mode] in the theme picker. `system` reuses "Follow
/// device" so both pickers on this page describe the same idea the same way.
String _themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Follow device',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};
