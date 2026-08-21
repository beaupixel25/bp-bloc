import 'package:freezed_annotation/freezed_annotation.dart';

part 'meter_view_model.freezed.dart';

/// How strong a password looks, on the five-step ramp the meter draws.
///
/// The ordinal matters: [PasswordStrengthMeterViewModel.evaluate] counts
/// satisfied rules and indexes this enum by the total.
enum PasswordStrength {
  /// No password typed yet. The meter is an empty track with no label.
  empty,

  /// Meets nothing, or only length. Still submittable.
  short,

  /// Long enough to be worth typing.
  okay,

  /// Mixed case as well as length.
  good,

  /// Length, mixed case, a digit and a symbol.
  strong,
}

/// {@template password_strength_meter_view_model}
/// The scored state a `PasswordStrengthMeter` draws.
///
/// Backticked, not a doc link: this file imports only `freezed_annotation`, so
/// the widget is genuinely out of scope here and a link would be a dangling
/// `comment_references`. The dependency runs the other way on purpose — the
/// scoring must be testable without pumping a frame.
///
/// **The meter informs; it never blocks and never scolds.** Nothing here feeds
/// a validation gate — a five-character password scores
/// [PasswordStrength.short] and the form still submits it, because the only
/// hard rule is the minimum length the form itself enforces. Keep it that way:
/// a strength meter that blocks submission turns a hint into a hurdle.
///
/// [fraction] is how much of the track to fill, 0..1. [strength] picks the
/// colour and the caption.
/// {@endtemplate}
@freezed
sealed class PasswordStrengthMeterViewModel
    with _$PasswordStrengthMeterViewModel {
  /// {@macro password_strength_meter_view_model}
  const factory PasswordStrengthMeterViewModel({
    required PasswordStrength strength,
    required double fraction,
  }) = _PasswordStrengthMeterViewModel;

  const PasswordStrengthMeterViewModel._();

  /// Scores [password] on four independent rules, then maps the count onto the
  /// ramp.
  ///
  /// The rules are cumulative but not ordered — a 20-character all-lowercase
  /// password satisfies two (length 8, length 12) and scores
  /// [PasswordStrength.okay]; `aB1!` satisfies two (mixed case, digit and
  /// symbol) and scores the same. That is deliberate: length and variety are
  /// worth the same to an attacker's search space, so the meter should not
  /// push people towards one over the other.
  ///
  /// An empty password is [PasswordStrength.empty] with an empty track, not a
  /// zero-scored "short" — showing a filled sliver before anything is typed
  /// reads as a failure the user has not had a chance to cause.
  ///
  /// Anything under [minimumLength] is [PasswordStrength.short] whatever else
  /// it satisfies. The variety rules are otherwise length-blind, and without
  /// this floor `Ab1!` — four characters — would satisfy two of them and read
  /// "Good", one rung below a password the form will actually accept.
  factory PasswordStrengthMeterViewModel.evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthMeterViewModel(
        strength: PasswordStrength.empty,
        fraction: 0,
      );
    }
    if (password.length < minimumLength) {
      return const PasswordStrengthMeterViewModel(
        strength: PasswordStrength.short,
        fraction: 0.18,
      );
    }

    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (_hasUpper.hasMatch(password) && _hasLower.hasMatch(password)) score++;
    if (_hasDigit.hasMatch(password) && _hasSymbol.hasMatch(password)) score++;

    // score 0..4 -> short, okay, good, strong, strong. The top two both read
    // "Strong"; only the fill differs, so a password that already qualifies is
    // never told it could try harder.
    const strengths = [
      PasswordStrength.short,
      PasswordStrength.okay,
      PasswordStrength.good,
      PasswordStrength.strong,
      PasswordStrength.strong,
    ];
    const fractions = [0.18, 0.42, 0.68, 0.86, 1.0];

    return PasswordStrengthMeterViewModel(
      strength: strengths[score],
      fraction: fractions[score],
    );
  }

  /// The length below which nothing scores above [PasswordStrength.short].
  ///
  /// Mirrors the form's own minimum. It is not enforced here — the meter never
  /// blocks — it only stops the ramp from flattering a password the form will
  /// reject anyway.
  static const int minimumLength = 8;

  static final RegExp _hasUpper = RegExp('[A-Z]');
  static final RegExp _hasLower = RegExp('[a-z]');
  static final RegExp _hasDigit = RegExp('[0-9]');
  static final RegExp _hasSymbol = RegExp('[^A-Za-z0-9]');

  /// The caption shown beside the track. Empty while nothing is typed.
  String get label => switch (strength) {
        PasswordStrength.empty => '',
        PasswordStrength.short => 'Short',
        PasswordStrength.okay => 'Okay',
        PasswordStrength.good => 'Good',
        PasswordStrength.strong => 'Strong',
      };
}
