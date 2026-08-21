import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'label_chip.freezed.dart';

/// A small, tappable pill-shaped label chip.
class LabelChip extends StatelessWidget {
  /// Creates a [LabelChip] showing [label] and invoking [onTapped] on tap.
  const LabelChip({
    required this.label,
    required this.onTapped,
    super.key,
    this.theme,
  });

  /// The text displayed inside the chip.
  final String label;

  /// Called when the chip is tapped.
  final VoidCallback onTapped;

  /// Optional styling override; defaults to [LabelChipThemeData.fallback].
  final LabelChipThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? LabelChipThemeData.fallback(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapped,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: IntrinsicWidth(
          child: AnimatedContainer(
            height: theme.height,
            duration: const Duration(milliseconds: 150),
            padding: theme.containerPadding,
            decoration: theme.containerDecoration,
            child: Align(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contains the theme information used by the TopicChip
@freezed
sealed class LabelChipThemeData with _$LabelChipThemeData {
  const factory LabelChipThemeData({
    required EdgeInsets containerPadding,
    required BoxDecoration containerDecoration,
    @Default(42) double height,
  }) = _LabelChipThemeData;

  /// Create the default theme used with List components.
  factory LabelChipThemeData.fallback(
    BuildContext context, {
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return LabelChipThemeData(
      containerPadding: EdgeInsets.symmetric(
        horizontal: isSelected ? 15 : 16,
        vertical: 10,
      ),
      containerDecoration: BoxDecoration(
        color: isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
