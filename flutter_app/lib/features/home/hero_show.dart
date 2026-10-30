import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// The show on the big card at the top of the home screen.
///
/// The one set « À la une » from the dashboard wins, as long as it can still
/// be booked. Otherwise the active show whose next episode is soonest, then
/// the most-reserved active one, so the home never opens without a hero.
Show pickHeroShow(List<Show> shows, DateTime now) {
  for (final show in shows) {
    if (show.isFeatured && show.isActive && show.hasUpcomingEpisodes) {
      return show;
    }
  }

  // Effective date helper: prefer next episode date, fall back to top-level
  DateTime? effectiveDate(Show show) =>
      show.nextEpisode?.startsAt ?? show.startsAt;

  Show? soonest(bool Function(Show) test) => shows.where((show) {
        final date = effectiveDate(show);
        return date != null && date.isAfter(now) && show.isActive && test(show);
      }).fold<Show?>(null, (prev, show) {
        if (prev == null) return show;
        return effectiveDate(show)!.isBefore(effectiveDate(prev)!)
            ? show
            : prev;
      });

  return soonest((show) => show.hasUpcomingEpisodes) ??
      // Fallback: any active upcoming show (backward compat)
      soonest((_) => true) ??
      // No dated upcoming show at all (e.g. everything is "Date à confirmer").
      // Still surface a hero so the home doesn't open on a cramped section
      // header — prefer the most-reserved active show, else just the first.
      (List<Show>.from(shows)
            ..sort((a, b) => b.reservedSeats.compareTo(a.reservedSeats)))
          .firstWhere((show) => show.isActive, orElse: () => shows.first);
}
