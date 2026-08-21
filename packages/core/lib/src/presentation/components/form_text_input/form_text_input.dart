import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_text_input.freezed.dart';

/// A common text input component used to capture user text input.
///
/// The [theme] can be customized to change the widget's appearance,
/// including [InputDecoration], [TextStyle], and other styling options.
class FormTextInput<T> extends StatefulWidget {
  /// Creates a [FormTextInput] driven by [viewModel].
  const FormTextInput({
    required this.viewModel,
    super.key,
    this.theme,
    this.controller,
    this.onChange,
    this.onSaved,
    this.onTapped,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.onSuffixIconPressed,
    this.onPrefixIconPressed,
    this.focusNode,
  });

  /// The view model that encapsulates the state and configuration for the
  /// [TextFormField].
  final FormTextInputViewModel<T> viewModel;

  /// The theme that defines the visual styling of the [TextFormField].
  final FormTextInputThemeData? theme;

  /// The controller for the [TextFormField].
  final TextEditingController? controller;

  /// Callback function invoked when the text in the [TextFormField] changes.
  final ValueChanged<String>? onChange;

  /// Callback function invoked when the [TextFormField] is saved.
  final FormFieldSetter<String>? onSaved;

  /// Callback function invoked when the [TextFormField] is tapped.
  final VoidCallback? onTapped;

  /// Callback function invoked when the [TextFormField] is edited.
  final VoidCallback? onEditingComplete;

  /// Callback function invoked when the field is submitted from the keyboard.
  final ValueChanged<String>? onFieldSubmitted;

  /// Validates the current field value, returning an error string or `null`.
  final FormFieldValidator<String>? validator;

  /// Optional icon shown at the end of the field.
  final Widget? suffixIcon;

  /// Optional icon shown at the start of the field.
  final Widget? prefixIcon;

  /// Callback function invoked when the suffix icon is pressed.
  final VoidCallback? onSuffixIconPressed;

  /// Callback function invoked when the prefix icon is pressed.
  final VoidCallback? onPrefixIconPressed;

  /// Optional focus node controlling this field's focus.
  final FocusNode? focusNode;

  @override
  State<FormTextInput<T>> createState() => _FormTextInputState<T>();
}

class _FormTextInputState<T> extends State<FormTextInput<T>> {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  bool get hasError => widget.viewModel.errorText?.isNotEmpty == true;
  bool get hasInput => _controller?.text.isNotEmpty == true;
  bool get isFocused => _focusNode?.hasFocus == true && !hasError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.controller == null && widget.viewModel.inputValue.isNotEmpty) {
      _controller!.text = widget.viewModel.inputValue;
    }

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode?.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant FormTextInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      final oldText = _controller?.text;

      if (oldWidget.controller == null) {
        _controller?.dispose();
      }

      _controller = widget.controller ?? TextEditingController(text: oldText);
    }

    final theme = widget.theme ?? FormTextInputTheme.of(context);
    final controller = _controller;
    final focusNode = _focusNode;
    // Only sync from viewModel when the controller is internally owned. When
    // the caller provides their own controller, that controller is the source
    // of truth — overwriting it on rebuild erases user input on focus loss.
    if (widget.controller == null &&
        controller != null &&
        (focusNode == null || !focusNode.hasFocus || theme.readOnly) &&
        controller.text != widget.viewModel.inputValue) {
      // Synchronize the controller text with the ViewModel's input value. If
      // the update happens during a persistent callback (e.g., during build or
      // layout), schedule it for the next frame to avoid "setState during
      // build" errors.
      if (WidgetsBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && controller.text != widget.viewModel.inputValue) {
            controller.text = widget.viewModel.inputValue;
          }
        });
      } else {
        controller.text = widget.viewModel.inputValue;
      }
    }

    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode?.removeListener(_onFocusChanged);
      if (oldWidget.focusNode == null) {
        _focusNode?.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode?.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    }

    _focusNode?.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? FormTextInputTheme.of(context);

    final Widget? prefixIconWidget;
    if (widget.prefixIcon != null) {
      if (widget.onPrefixIconPressed != null) {
        prefixIconWidget = IconButton(
          icon: widget.prefixIcon!,
          color: theme.prefixIconColor,
          onPressed: widget.onPrefixIconPressed,
          iconSize: theme.prefixIconSize,
          padding: theme.prefixIconPadding,
          constraints: theme.prefixIconConstraints,
        );
      } else {
        prefixIconWidget = Padding(
          padding: theme.prefixIconPadding ?? EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: theme.prefixIconConstraints ?? const BoxConstraints(),
            child: Align(
              child: IconTheme.merge(
                data: IconThemeData(
                  color: theme.prefixIconColor,
                  size: theme.prefixIconSize,
                ),
                child: widget.prefixIcon!,
              ),
            ),
          ),
        );
      }
    } else {
      prefixIconWidget = null;
    }

    final Widget? suffixIconWidget;
    if (widget.suffixIcon != null) {
      if (widget.onSuffixIconPressed != null) {
        suffixIconWidget = IconButton(
          icon: widget.suffixIcon!,
          color: theme.suffixIconColor,
          onPressed: widget.onSuffixIconPressed,
          hoverColor: theme.suffixIconHoverColor,
          iconSize: theme.suffixIconSize,
          padding: theme.suffixIconPadding,
          constraints: theme.suffixIconConstraints,
        );
      } else {
        suffixIconWidget = Padding(
          padding: theme.suffixIconPadding ?? EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: theme.suffixIconConstraints ?? const BoxConstraints(),
            child: Align(
              child: IconTheme.merge(
                data: IconThemeData(
                  color: theme.suffixIconColor,
                  size: theme.suffixIconSize,
                ),
                child: widget.suffixIcon!,
              ),
            ),
          ),
        );
      }
    } else {
      suffixIconWidget = null;
    }

    return GestureDetector(
      onTap: theme.isDisabled ? null : () => _focusNode?.requestFocus(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: theme.height,
            decoration: theme.decoration.copyWith(
              border: hasError
                  ? theme.errorBorder
                  : (isFocused ? theme.focusedBorder : null),
            ),
            padding: EdgeInsets.only(
              left: theme.containerPadding.left,
              right: theme.containerPadding.right,
            ),
            child: Row(
              children: [
                ?prefixIconWidget,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: theme.containerPadding.top,
                      bottom:
                          (widget.viewModel.labelText != null &&
                              (_focusNode!.hasFocus || hasInput))
                          ? 4
                          : theme.containerPadding.bottom,
                    ),
                    child: TextFormField(
                      enabled: !theme.isDisabled,
                      controller: _controller,
                      focusNode: _focusNode,
                      obscureText: widget.viewModel.isInputObscured,
                      obscuringCharacter: widget.viewModel.obscuringCharacter,
                      enableSuggestions: !widget.viewModel.isInputObscured,
                      autocorrect: !widget.viewModel.isInputObscured,
                      onChanged: widget.onChange,
                      onSaved: widget.onSaved,
                      readOnly: theme.readOnly,
                      onTap: widget.onTapped,
                      textCapitalization:
                          widget.viewModel.textCapitalization ??
                          TextCapitalization.none,
                      keyboardType:
                          widget.viewModel.textInputType ?? TextInputType.text,
                      onEditingComplete: widget.onEditingComplete,
                      onFieldSubmitted: widget.onFieldSubmitted,
                      textInputAction: widget.viewModel.textInputAction,
                      inputFormatters: widget.viewModel.inputFormatters,
                      decoration: theme.inputDecoration.copyWith(
                        isDense: true,
                        hintText: widget.viewModel.hintText,
                        labelText: widget.viewModel.labelText,
                        helperText: widget.viewModel.infoText,
                        fillColor: theme.inputDecoration.fillColor,
                      ),
                      style: theme.inputTextStyle,
                      strutStyle: theme.strutStyle,
                      cursorWidth: 1,
                      maxLength: theme.maxLength,
                      validator: widget.validator,
                      cursorColor: theme.cursorColor,
                      minLines: theme.minLines,
                      maxLines: theme.maxLines,
                      autovalidateMode: widget.viewModel.autoValidateMode,
                      autofocus: widget.viewModel.isAutoFocused,
                      cursorHeight: theme.cursorHeight,
                      cursorRadius: theme.cursorRadius,
                    ),
                  ),
                ),
                ?suffixIconWidget,
              ],
            ),
          ),
          if (widget.viewModel.errorText?.isNotEmpty ?? false)
            Text(
              widget.viewModel.errorText!,
              style: theme.inputDecoration.errorStyle,
            ),
        ],
      ),
    );
  }
}

/// The styling contract for [FormTextInput].
@freezed
sealed class FormTextInputThemeData with _$FormTextInputThemeData {
  factory FormTextInputThemeData({
    required BoxDecoration decoration,
    required InputDecoration inputDecoration,
    required TextStyle inputTextStyle,
    required StrutStyle strutStyle,
    required Color cursorColor,
    required double cursorHeight,
    required Radius cursorRadius,
    required EdgeInsets containerPadding,
    required BoxBorder focusedBorder,
    required BoxBorder errorBorder,
    @Default(60) double height,
    double? cursorWidth,
    int? maxLength,
    @Default(1) int minLines,
    @Default(1) int maxLines,
    @Default(false) bool readOnly,
    @Default(false) bool isDisabled,
    Color? suffixIconColor,
    Color? prefixIconColor,
    Color? suffixIconHoverColor,
    double? suffixIconSize,
    EdgeInsetsGeometry? suffixIconPadding,
    BoxConstraints? suffixIconConstraints,
    double? prefixIconSize,
    EdgeInsetsGeometry? prefixIconPadding,
    BoxConstraints? prefixIconConstraints,
  }) = _FormTextInputThemeData;

  factory FormTextInputThemeData.fallback(
    BuildContext context, {
    bool showSuffixIcon = false,
    bool showPrefixIcon = false,
    bool isReadOnly = false,
    bool isDisabled = false,
    bool showBorder = false,
    bool includeFillColor = true,
    bool isHintDisabled = false,
    bool isActive = false,
    double? height,
    double suffixIconSize = 24.0,
    EdgeInsetsGeometry suffixIconPadding = EdgeInsets.zero,
    BoxConstraints suffixIconConstraints = const BoxConstraints(
      minWidth: 40,
      minHeight: 40,
    ),
    double prefixIconSize = 24.0,
    EdgeInsetsGeometry prefixIconPadding = EdgeInsets.zero,
    BoxConstraints prefixIconConstraints = const BoxConstraints(
      minWidth: 40,
      minHeight: 40,
    ),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderSide = BorderSide(
      color: Colors.transparent,
      style: showBorder ? BorderStyle.solid : BorderStyle.none,
    );
    final InputBorder inputBorder = OutlineInputBorder(borderSide: borderSide);
    final inputTextStyle = theme.textTheme.bodySmall!;
    final disabledTextInputColor = colorScheme.onSurfaceVariant;
    final colorExtension = Theme.of(context).extension<ColorExtension>();
    final inputFillColor = includeFillColor
        ? colorScheme.surfaceContainer
        : colorExtension!.transparentColor;
    final BoxBorder focusedBorder = Border.all(
      color: colorScheme.tertiary,
      width: 2,
    );
    final BoxBorder errorBorder = Border.all(
      color: colorScheme.error,
      width: 2,
    );

    return FormTextInputThemeData(
      height: height ?? defaultHeight,
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(8),
        border: !includeFillColor
            ? Border.all(
                color: colorScheme.outlineVariant,
                width: 2,
              )
            : isActive
            ? focusedBorder
            : Border.all(
                color: Colors.transparent,
                width: 2,
              ),
      ),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: inputFillColor,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        errorBorder: inputBorder,
        focusedErrorBorder: inputBorder,
        contentPadding: EdgeInsets.only(top: isHintDisabled ? 6 : 16),
        labelStyle: inputTextStyle,
        hintStyle: inputTextStyle.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.5,
        ),
        errorStyle: theme.textTheme.bodySmall!.copyWith(
          color: colorScheme.error,
        ),
        helperStyle: theme.textTheme.bodySmall!.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1,
        ),
        errorMaxLines: 1,
        disabledBorder: inputBorder,
      ),
      inputTextStyle: inputTextStyle.copyWith(
        color: isDisabled ? disabledTextInputColor : colorScheme.onSurface,
        height: 1,
      ),
      cursorWidth: 1.5,
      prefixIconColor: showPrefixIcon ? colorScheme.onSurfaceVariant : null,
      suffixIconColor: showSuffixIcon ? colorScheme.onSurfaceVariant : null,
      suffixIconHoverColor: showSuffixIcon
          ? Theme.of(context).extension<ColorExtension>()!.transparentColor
          : null,
      strutStyle: StrutStyle.fromTextStyle(inputTextStyle),
      cursorColor: colorScheme.onSurface,
      cursorHeight: 16,
      cursorRadius: const Radius.circular(10),
      containerPadding: EdgeInsets.only(
        left: showPrefixIcon ? 8 : 16,
        right: showSuffixIcon ? 0 : 16,
        top: isHintDisabled ? 14 : 18,
        bottom: isHintDisabled ? 14 : 16,
      ),
      readOnly: isReadOnly,
      isDisabled: isDisabled,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      suffixIconSize: suffixIconSize,
      suffixIconPadding: suffixIconPadding,
      suffixIconConstraints: suffixIconConstraints,
      prefixIconSize: prefixIconSize,
      prefixIconPadding: prefixIconPadding,
      prefixIconConstraints: prefixIconConstraints,
    );
  }

  /// The default input height used when none is supplied.
  static const double defaultHeight = 60;
}

/// The [InheritedWidget] that propagates a [FormTextInputThemeData] down the
/// tree so descendant [FormTextInput]s can resolve their styling.
class FormTextInputTheme extends InheritedWidget {
  /// Creates a [FormTextInputTheme] exposing [data] to its subtree.
  const FormTextInputTheme({
    required super.child,
    required this.data,
    super.key,
  });

  /// The theme data exposed to descendants.
  final FormTextInputThemeData data;

  @override
  bool updateShouldNotify(FormTextInputTheme oldWidget) {
    return data != oldWidget.data;
  }

  /// Resolves the nearest [FormTextInputThemeData], falling back to
  /// [FormTextInputThemeData.fallback] when none is in scope.
  static FormTextInputThemeData of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<FormTextInputTheme>();

    return result?.data ?? FormTextInputThemeData.fallback(context);
  }
}
