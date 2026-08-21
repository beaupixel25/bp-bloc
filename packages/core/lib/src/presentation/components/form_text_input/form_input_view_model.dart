import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_input_view_model.freezed.dart';

/// The data and behavioural state of a form input, independent of its styling.
@Freezed(genericArgumentFactories: true)
sealed class FormInputViewModel<T> with _$FormInputViewModel<T> {
  const factory FormInputViewModel.text({
    String? labelText,
    String? hintText,
    String? infoText,
    @Default(true) bool showInfoTextWhenFocusedOnly,
    String? errorText,
    @Default('') String inputValue,
    T? value,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    String? suffixIconAsset,
    String? obscuredSuffixIconAsset,
    @Default(false) bool isInputObscured,
    @Default('•') String obscuringCharacter,
    TextInputType? textInputType,
    @Default(false) bool isHidden,
    @Default(false) bool isAutoFocused,
    int? maxLength,
    AutovalidateMode? autoValidateMode,
    List<TextInputFormatter>? inputFormatters,
  }) = FormTextInputViewModel;

  const factory FormInputViewModel.singleSelect({
    dynamic id,
    String? errorText,
    String? labelText,
    String? hintText,
    String? infoText,
    T? value,

    /// The list of options to select from.
    /// This list can be empty in cases where a select control doesn't offer
    /// a list of options, rather generating the options and displaying them
    /// dynamically. (e.g. Loading a list from the server dynamically, or
    /// displaying a date picker for the user to select, etc...)
    List<SelectOptionViewModel<T>>? options,
    @Default(false) bool isHidden,
    @Default(false) bool isReadOnly,
    @Default(false) bool isDisabled,
  }) = SingleSelectInputViewModel;
}

/// A single selectable option for a select-style [FormInputViewModel].
@Freezed(genericArgumentFactories: true)
sealed class SelectOptionViewModel<T> with _$SelectOptionViewModel<T> {
  const factory SelectOptionViewModel({
    /// The value of the option.
    /// This can be null to support ui-only options that can have no values.
    required T value,

    /// The text appearing as the option
    required String name,

    /// The description that appears under the name
    String? description,
  }) = _SelectOptionViewModel;
}
