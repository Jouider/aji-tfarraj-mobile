/// One prescribed shot, and how to take it.
///
/// Lives here rather than in either language file: both implement the same
/// contract, and the analyser then refuses a build where one language is
/// missing a string the other has. In a bilingual app that is the only
/// mechanism that reliably catches a half-translated screen.
class CastingPoseCopy {
  final String label;

  /// The one line kept on screen while the camera is up — anything longer is
  /// not read by someone already standing in position.
  final String hint;

  /// The full instructions, read before the camera opens.
  final List<String> steps;

  const CastingPoseCopy({
    required this.label,
    required this.hint,
    required this.steps,
  });
}

/// Everything the casting section says, in one language.
abstract class CastingCopy {
  String get title;
  String get subtitle;
  String get bookTitle;
  String get bookIntro;
  String get bookHelper;
  String get bookRequired;
  String get bookOptional;
  String get bookComplete;
  String get bookMissing;
  String get bookRetake;
  String get bookDelete;
  String get bookTake;
  String get rulesTitle;
  List<String> get rules;
  CastingPoseCopy get fullFront;
  CastingPoseCopy get fullProfile;
  CastingPoseCopy get portrait;
  CastingPoseCopy get fullBack;
  CastingPoseCopy get portraitSmile;
  String get measurementsTitle;
  String get measurementsIntro;
  String get height;
  String get weight;
  String get clothingSize;
  String get shoeSize;
  String get save;
  String get saved;
  String get tabCastings;
  String get tabPublications;
  String get noCastings;
  String get noCastingsSubtitle;
  String get closesAt;
  String get apply;
  String get applied;
  String get applyBlocked;
  String get applyNote;
  String get applyNoteHint;
  String get applySent;
  String get applyError;
  String get myApplications;
  String get noApplications;
  String get noApplicationsSubtitle;
  String get withdraw;
  String get withdrawConfirm;
  String get withdrawn;
  String get statusPending;
  String get statusShortlisted;
  String get statusAccepted;
  String get statusRejected;
  String get statusUnknown;
  String get adultsOnly;
  String get birthdayRequired;
  String get completeProfile;
  String get loadError;
  String get photoError;
  String get profileTile;
  String get profileTileSubtitle;

  // Opening a call
  String get infoTitle;
  String get infoDate;
  String get infoLocation;
  String get infoCompensation;
  String get aboutTitle;
  String get callRulesTitle;
  String get detailsLoadError;

  // Checking a casting shot after it is taken
  String get poseNoPerson;
  String get poseHeadCut;
  String get poseFeetCut;
  String get poseNotFacing;
  String get poseNotSideways;
  String get portraitNotSmiling;
  String get adviceTitle;
  String get adviceKeep;
}
