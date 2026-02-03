DateTime toBoliviaTime(DateTime dateTime) {
  // Bolivia is UTC-4 year round (no DST)
  final utc = dateTime.toUtc();
  return utc.subtract(const Duration(hours: 4));
}
