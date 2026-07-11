import 'package:bloody/features/receiver/map_finder/presentation/providers/receiver_map_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confirmation cooldown blocks before 24 hours', () {
    final state = ReceiverMapState(
      lastConfirmationAt: DateTime.now().subtract(const Duration(hours: 23)),
    );

    expect(state.isOnConfirmationCooldown, isTrue);
    expect(state.confirmationCooldownFormatted, isNotEmpty);
  });

  test('confirmation cooldown ends after 24 hours', () {
    final state = ReceiverMapState(
      lastConfirmationAt: DateTime.now().subtract(
        const Duration(hours: 24, minutes: 1),
      ),
    );

    expect(state.isOnConfirmationCooldown, isFalse);
    expect(state.confirmationCooldownFormatted, isEmpty);
  });
}
