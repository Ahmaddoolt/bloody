class EligibilityEntity {
  final bool isEligible;
  final DateTime? lastDonationDate;
  final DateTime? nextEligibleDate;
  final int daysRemaining;

  const EligibilityEntity({
    required this.isEligible,
    this.lastDonationDate,
    this.nextEligibleDate,
    required this.daysRemaining,
  });

  factory EligibilityEntity.fromLastDonation(DateTime? lastDonationDate) {
    if (lastDonationDate == null) {
      return const EligibilityEntity(
        isEligible: true,
        daysRemaining: 0,
      );
    }

    final nextEligible = lastDonationDate.add(const Duration(days: 90));
    final now = DateTime.now();
    final isEligible = now.isAfter(nextEligible);
    final daysRemaining = isEligible ? 0 : nextEligible.difference(now).inDays;

    return EligibilityEntity(
      isEligible: isEligible,
      lastDonationDate: lastDonationDate,
      nextEligibleDate: nextEligible,
      daysRemaining: daysRemaining,
    );
  }

  String get formattedTimeRemaining {
    if (isEligible) return '';

    final nextDate = nextEligibleDate!;
    final now = DateTime.now();
    final diff = nextDate.difference(now);

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    return '${days}d ${hours}h ${minutes}m';
  }
}
