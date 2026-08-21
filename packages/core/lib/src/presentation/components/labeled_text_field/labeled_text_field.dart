import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'labeled_text_field.freezed.dart';

/// {@template labeled_text_field}
/// A single-line text field with its label **above** it rather than inside.
///
/// This is the outlined, label-above cut of the design system's input, and it
/// is a different component from [FormTextInput] rather than a variant of it:
///
/// * [FormTextInput] is the filled input with a floating in-field label. Use it
///   for dense forms.
/// * [LabeledTextField] is the outlined input whose label is a separate,
///   always-visible caption. Use it wherever the label must stay readable while
///   the field has content — every authentication screen does.
///
/// A placeholder is an example, never the label: [hintText] may be omitted, but
/// [labelText] may not. The label is a real [Text] above the field, so it stays
/// legible at any text scale instead of shrinking into the border.
///
/// Anything that has to sit under the field — a strength meter, a counter —
/// goes in [footer], inside the same labelled group.
/// {@endtemplate}
class LabeledTextField extends StatefulWidget {
  /// {@macro labeled_text_field}
  const LabeledTextField({
    required this.labelText,
    super.key,
    this.controller,
    this.theme,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.trailing,
    this.footer,
    this.focusNode,
  });

  /// The always-visible caption above the field. Required — see the class doc.
  final String labelText;

  /// Holds the text. Supply one when the page owns the value.
  final TextEditingController? controller;

  /// Styling. Defaults to the nearest [LabeledTextFieldTheme], then to
  /// [LabeledTextFieldThemeData.fallback] for the ambient theme.
  final LabeledTextFieldThemeData? theme;

  /// An example of what to type. Never the only label.
  final String? hintText;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The soft keyboard to raise.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Autofill hints, e.g. `[AutofillHints.email]`.
  final List<String>? autofillHints;

  /// Whether the text is masked.
  final bool obscureText;

  /// Whether the field accepts input.
  final bool enabled;

  /// An action pinned to the right inside the field — typically an
  /// [IconActionButton] such as a show/hide password toggle.
  final Widget? trailing;

  /// Rendered directly beneath the field, inside the labelled group.
  final Widget? footer;

  /// Controls focus externally. One is created internally when omitted.
  final FocusNode? focusNode;

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  void _attachFocusNode(FocusNode? external) {
    _ownsFocusNode = external == null;
    _focusNode = external ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant LabeledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? LabeledTextFieldTheme.of(context);
    final isFocused = _focusNode.hasFocus;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          theme.isLabelUppercased
              ? widget.labelText.toUpperCase()
              : widget.labelText,
          style: theme.labelStyle,
        ),
        SizedBox(height: theme.labelGap),
        AnimatedContainer(
          height: theme.height,
          duration: theme.focusDuration,
          curve: theme.curve,
          decoration: BoxDecoration(
            color: theme.fill,
            borderRadius: BorderRadius.circular(theme.radius),
            // The focus ring is drawn *inside* the field rather than as an
            // outset ring, so the row height stays [theme.height] whether or
            // not the field has focus — an outset ring relayouts the whole
            // form on every focus change.
            border: Border.all(
              color: isFocused ? theme.focusRing : theme.outline,
              width: isFocused ? theme.focusRingWidth : theme.outlineWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: theme.contentPadding.left,
                    right: widget.trailing == null
                        ? theme.contentPadding.right
                        : 0,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    obscureText: widget.obscureText,
                    enableSuggestions: !widget.obscureText,
                    autocorrect: !widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    autofillHints: widget.autofillHints,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: theme.textStyle,
                    cursorColor: theme.cursorColor,
                    cursorWidth: theme.cursorWidth,
                    inputFormatters: const [
                      // A single-line field: a pasted newline should not
                      // silently become a space-looking glyph.
                      _SingleLineFormatter(),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hintText,
                      hintStyle: theme.hintStyle,
                      // No `labelText` on purpose: the visible caption above
                      // is the label, and setting it here too would float a
                      // second copy inside the field and announce it twice.
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: EdgeInsets.only(right: theme.trailingInset),
                  child: widget.trailing,
                ),
            ],
          ),
        ),
        if (widget.footer != null) ...[
          SizedBox(height: theme.footerGap),
          widget.footer!,
        ],
      ],
    );
  }
}

/// Collapses any newline a paste introduces, keeping the field single-line.
class _SingleLineFormatter extends TextInputFormatter {
  const _SingleLineFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains('\n')) return newValue;
    final text = newValue.text.replaceAll('\n', '');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, text.length),
      ),
    );
  }
}

/// The styling contract for [LabeledTextField].
@freezed
sealed class LabeledTextFieldThemeData with _$LabeledTextFieldThemeData {
  /// Creates a fully specified field style.
  factory LabeledTextFieldThemeData({
    required Color fill,
    required Color outline,
    required Color focusRing,
    required Color cursorColor,
    required TextStyle labelStyle,
    required TextStyle textStyle,
    required TextStyle hintStyle,
    required double height,
    required double radius,
    required EdgeInsets contentPadding,

    /// Whether the caption is upper-cased before it is drawn.
    ///
    /// A styling decision, so it lives here rather than in the widget: a
    /// design system whose captions are sentence case turns this off in its
    /// theme instead of every call site passing a pre-shouted string.
    @Default(true) bool isLabelUppercased,
    @Default(7) double labelGap,
    @Default(6) double footerGap,
    @Default(5) double trailingInset,
    @Default(1) double outlineWidth,
    @Default(2) double focusRingWidth,
    @Default(1.5) double cursorWidth,
    @Default(Duration(milliseconds: 180)) Duration focusDuration,
    @Default(Cubic(0.22, 0.61, 0.36, 1)) Curve curve,
  }) = _LabeledTextFieldThemeData;

  /// Derives the field style from the ambient theme.
  factory LabeledTextFieldThemeData.fallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimensions = DimensionExtension.of(context);

    return LabeledTextFieldThemeData(
      fill: colorScheme.surface,
      outline: colorScheme.outline,
      // Secondary, not tertiary: tertiary is the success colour elsewhere in
      // the kit, and a focus ring in it reads as "this field is now correct".
      focusRing: colorScheme.secondary,
      cursorColor: colorScheme.onSurface,
      labelStyle: theme.textTheme.labelMedium!.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      textStyle: theme.textTheme.titleMedium!.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: theme.textTheme.titleMedium!.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      // Spelled out rather than referencing the static below, for the same
      // reason the `@Default`s above are: a freezed expression is copied into
      // the generated file verbatim, where a bare class member does not
      // resolve, and `dart analyze` does not catch it.
      height: 52,
      radius: dimensions.radiusMd,
      contentPadding: EdgeInsets.symmetric(horizontal: dimensions.space16),
    );
  }

  /// The kit's input height. Matches [PillButtonThemeData.defaultHeight] so a
  /// field and a button stacked in a form share one rhythm.
  static const double defaultHeight = 52;
}

/// The [InheritedWidget] that propagates a [LabeledTextFieldThemeData] to
/// descendant [LabeledTextField]s.
class LabeledTextFieldTheme extends InheritedWidget {
  /// Creates a [LabeledTextFieldTheme] exposing [data] to its subtree.
  const LabeledTextFieldTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final LabeledTextFieldThemeData data;

  @override
  bool updateShouldNotify(LabeledTextFieldTheme oldWidget) =>
      data != oldWidget.data;

  /// Resolves the nearest [LabeledTextFieldThemeData], falling back to
  /// [LabeledTextFieldThemeData.fallback] when none is in scope.
  static LabeledTextFieldThemeData of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<LabeledTextFieldTheme>();

    return result?.data ?? LabeledTextFieldThemeData.fallback(context);
  }
}
