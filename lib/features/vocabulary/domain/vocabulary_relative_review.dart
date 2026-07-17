/// Relative next-review labels for All Words list rows.
library;

/// Calendar-relative label for when a word is next due.
///
/// Compare [nextReviewAt] to [now] in **local** calendar days (midnight).
sealed class RelativeNextReviewLabel {
  const RelativeNextReviewLabel();
}

/// [nextReviewAt] is before today's local calendar day.
final class RelativeNextReviewOverdue extends RelativeNextReviewLabel {
  const RelativeNextReviewOverdue();
}

/// [nextReviewAt] falls on today's local calendar day.
final class RelativeNextReviewToday extends RelativeNextReviewLabel {
  const RelativeNextReviewToday();
}

/// [nextReviewAt] falls on tomorrow's local calendar day.
final class RelativeNextReviewTomorrow extends RelativeNextReviewLabel {
  const RelativeNextReviewTomorrow();
}

/// [nextReviewAt] is [days] local calendar days after today (`days >= 2`).
final class RelativeNextReviewInDays extends RelativeNextReviewLabel {
  const RelativeNextReviewInDays(this.days);

  final int days;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelativeNextReviewInDays && days == other.days;

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'RelativeNextReviewInDays($days)';
}

/// Map [nextReviewAt] vs [now] to a [RelativeNextReviewLabel].
///
/// Day difference uses local dates truncated to midnight.
RelativeNextReviewLabel relativeNextReviewLabel({
  required DateTime nextReviewAt,
  required DateTime now,
}) {
  final reviewDay = _localMidnight(nextReviewAt);
  final today = _localMidnight(now);
  final days = reviewDay.difference(today).inDays;

  if (days < 0) return const RelativeNextReviewOverdue();
  if (days == 0) return const RelativeNextReviewToday();
  if (days == 1) return const RelativeNextReviewTomorrow();
  return RelativeNextReviewInDays(days);
}

DateTime _localMidnight(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
