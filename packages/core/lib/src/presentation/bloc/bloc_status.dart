/// Lifecycle status carried by a bloc/cubit state so loaded data can survive a
/// later failure (e.g. a list stays visible while a refresh error is shown).
enum BlocStatus {
  /// No action has run yet.
  initial,

  /// An action is in flight.
  loading,

  /// The last action succeeded.
  success,

  /// The last action failed; see the accompanying `AppException`.
  failure,
}
