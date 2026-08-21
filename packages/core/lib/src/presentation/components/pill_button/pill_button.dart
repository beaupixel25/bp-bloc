import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pill_button.freezed.dart';

/// The three roles a [PillButton] can play on a screen.
///
/// One [primary] per screen. [secondary] is the equal-weight alternative beside
/// it; [ghost] is a label-only action with no container at all.
enum PillButtonVariant {
  /// Solid brand fill, no border, no shadow.
  primary,

  /// Surface fill with a 1px outline.
  secondary,

  /// No fill and no border — the label alone.
  ghost,
}

/// {@template pill_button}
/// A full-pill call to action with an optional leading busy spinner.
///
/// Three behaviours are contractual and easy to lose by reaching for a stock
/// [ElevatedButton] instead:
///
/// * **Disabled is opacity, never a grey fill.** A greyed-out brand colour
///   reads as a different, broken component; dimming the whole button reads as
///   "not yet".
/// * **Press is scale only.** `scale(0.98)` over
///   [PillButtonThemeData.pressDuration] with no colour flash — the fill is the
///   brand, and flashing it is loud.
/// * **Busy does not resize the button.** The spinner appears to the *left* of
///   an unchanged label. Swapping the label for a spinner makes the button jump
///   width, and the label is what tells the user what is in flight.
///
/// Pass [onPressed] as null to disable. A disabled or busy button does not
/// report taps.
/// {@endtemplate}
class PillButton extends StatefulWidget {
  /// {@macro pill_button}
  const PillButton({
    required this.label,
    super.key,
    this.onPressed,
    this.theme,
    this.isBusy = false,
    this.isEnabled = true,
    this.isDimmed = false,
    this.semanticLabel,
  });

  /// The button's text. Sentence case — "Log in", not "Log In".
  final String label;

  /// Invoked on tap. Null disables the button, exactly as [isEnabled] false
  /// does.
  final VoidCallback? onPressed;

  /// Styling. Defaults to the nearest [PillButtonTheme], then to
  /// [PillButtonThemeData.fallback] for the ambient theme.
  final PillButtonThemeData? theme;

  /// Shows the leading spinner and suppresses taps. The label is unchanged and
  /// the button keeps its width.
  final bool isBusy;

  /// Whether the button accepts taps. False dims it to
  /// [PillButtonThemeData.disabledOpacity] and stops it reporting them.
  final bool isEnabled;

  /// Dims the button to [PillButtonThemeData.disabledOpacity] **without**
  /// disabling it — the "not yet" look for a primary action whose form is
  /// incomplete.
  ///
  /// Use this, not [isEnabled], to gate a form's submit. A truly disabled CTA
  /// leaves someone tapping a control that silently does nothing with no way to
  /// find out why; a dimmed one still fires [onPressed], and the form answers
  /// with the message naming what is missing.
  final bool isDimmed;

  /// Overrides the announced label when [label] alone is ambiguous.
  final String? semanticLabel;

  /// Whether this button currently responds to a tap.
  bool get isInteractive => isEnabled && !isBusy && onPressed != null;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? PillButtonTheme.of(context);
    final isInteractive = widget.isInteractive;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isBusy) ...[
          SizedBox.square(
            dimension: theme.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: theme.spinnerStrokeWidth,
              color: theme.foreground,
            ),
          ),
          SizedBox(width: theme.spinnerGap),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: theme.labelStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        // The label is already announced by Semantics above; letting the Text
        // announce it again reads the button twice.
        child: AnimatedOpacity(
          opacity:
              isInteractive && !widget.isDimmed ? 1 : theme.disabledOpacity,
          duration: theme.opacityDuration,
          curve: theme.curve,
          child: AnimatedScale(
            scale: _isPressed ? theme.pressedScale : 1,
            duration: theme.pressDuration,
            curve: theme.curve,
            child: GestureDetector(
              onTapDown: isInteractive ? (_) => _setPressed(true) : null,
              onTapUp: isInteractive ? (_) => _setPressed(false) : null,
              onTapCancel: isInteractive ? () => _setPressed(false) : null,
              onTap: isInteractive ? widget.onPressed : null,
              // Opaque so the whole pill is the target, including the gaps
              // either side of a short label.
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: theme.height,
                padding: theme.padding,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(theme.radius),
                  border: theme.border,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The styling contract for [PillButton].
@freezed
sealed class PillButtonThemeData with _$PillButtonThemeData {
  /// Creates a fully specified button style.
  factory PillButtonThemeData({
    required Color background,
    required Color foreground,
    required TextStyle labelStyle,
    required double height,
    required double radius,
    required EdgeInsets padding,
    BoxBorder? border,
    @Default(0.4) double disabledOpacity,
    @Default(0.98) double pressedScale,
    @Default(Duration(milliseconds: 120)) Duration pressDuration,
    @Default(Duration(milliseconds: 200)) Duration opacityDuration,
    @Default(Cubic(0.22, 0.61, 0.36, 1)) Curve curve,
    @Default(16) double spinnerSize,
    @Default(2) double spinnerStrokeWidth,
    @Default(8) double spinnerGap,
  }) = _PillButtonThemeData;

  /// Derives a button style for [variant] from the ambient theme.
  ///
  /// Every value comes from `colorScheme`, `textTheme`, [ColorExtension] or
  /// [DimensionExtension]; none is a literal colour or size.
  factory PillButtonThemeData.fallback(
    BuildContext context, {
    PillButtonVariant variant = PillButtonVariant.primary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimensions = DimensionExtension.of(context);
    final colors = ColorExtension.of(context);

    final (Color background, Color foreground, BoxBorder? border) =
        switch (variant) {
      PillButtonVariant.primary => (
          colorScheme.primary,
          colorScheme.onPrimary,
          null,
        ),
      PillButtonVariant.secondary => (
          colorScheme.surface,
          colorScheme.onSurface,
          Border.all(color: colorScheme.outline),
        ),
      PillButtonVariant.ghost => (
          colors.transparentColor,
          colorScheme.onSurface,
          null,
        ),
    };

    return PillButtonThemeData(
      background: background,
      foreground: foreground,
      border: border,
      labelStyle: theme.textTheme.titleMedium!.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      // Spelled out rather than referencing the static below: a freezed
      // `@Default` expression is copied verbatim into the generated file, where
      // a bare class member does not resolve — and `dart analyze` does not
      // catch it. This one is a plain argument, but the habit is what keeps the
      // defaults above safe.
      height: 52,
      radius: dimensions.radiusPill,
      padding: EdgeInsets.symmetric(horizontal: dimensions.space24),
    );
  }

  /// The kit's `lg` height. Comfortably over the 44pt minimum touch target.
  static const double defaultHeight = 52;
}

/// The [InheritedWidget] that propagates a [PillButtonThemeData] to descendant
/// [PillButton]s.
class PillButtonTheme extends InheritedWidget {
  /// Creates a [PillButtonTheme] exposing [data] to its subtree.
  const PillButtonTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final PillButtonThemeData data;

  @override
  bool updateShouldNotify(PillButtonTheme oldWidget) => data != oldWidget.data;

  /// Resolves the nearest [PillButtonThemeData], falling back to
  /// [PillButtonThemeData.fallback] when none is in scope.
  static PillButtonThemeData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<PillButtonTheme>();

    return result?.data ?? PillButtonThemeData.fallback(context);
  }
}
