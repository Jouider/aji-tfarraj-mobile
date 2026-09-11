/// Copy for "Présents" — the door's list of who is in the room — and for the
/// departures recorded on it.
///
/// A contract, so French and Arabic cannot drift apart: a string added here and
/// missing in one language does not compile. Worded without gender: the person
/// in front of the scanner can be anyone.
abstract class DepartureCopy {
  // Where it is reached
  String get tile;
  String get tileSubtitle;

  // The list
  String get title;
  String get refresh;
  String get loadError;
  String get searchHint;
  String counts(int present, int left);
  String get empty;
  String get emptySubtitle;
  String get noMatch;
  String get walkIn;
  String broughtBy(String name);
  String checkedInAt(String time);
  String leftAt(String time);
  String excludedBefore(int count);

  /// The label for a reason key from the server (`left`, `unwell`, …).
  String reason(String key);

  // Recording a departure
  String get sheetTitle;
  String get reasonQuestion;
  String get noteLabel;
  String get noteHintOptional;
  String get noteRequired;
  String get consequence;
  String get consequenceWalkIn;
  String get exclusionNote;
  String get confirm;
  String get cancel;
  String get recorded;
  String get saveError;

  // A departure already recorded
  String recordedBy(String name);
  String get undo;
  String get undoConfirmTitle;
  String get undoConfirmBody;
  String get undone;

  // At the door, on the next visit
  String doorExcludedBefore(int count, String? date, String? show);
  String doorAlreadyLeft(String time, String reason);
}
