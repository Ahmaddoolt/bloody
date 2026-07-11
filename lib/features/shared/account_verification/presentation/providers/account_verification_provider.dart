import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/account_verification_repository.dart';
import '../../domain/entities/account_verification_request_entity.dart';

final accountVerificationRepositoryProvider =
    Provider<AccountVerificationRepository>((ref) {
  return AccountVerificationRepository();
});

final donorVerificationProvider = StateNotifierProvider<
    DonorVerificationNotifier,
    AsyncValue<AccountVerificationRequestEntity?>>((ref) {
  return DonorVerificationNotifier(
    ref.watch(accountVerificationRepositoryProvider),
  );
});

final adminVerificationProvider = StateNotifierProvider<
    AdminVerificationNotifier,
    AsyncValue<List<AccountVerificationRequestEntity>>>((ref) {
  return AdminVerificationNotifier(
    ref.watch(accountVerificationRepositoryProvider),
  );
});

class DonorVerificationNotifier
    extends StateNotifier<AsyncValue<AccountVerificationRequestEntity?>> {
  final AccountVerificationRepository _repository;

  DonorVerificationNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadLatest();
  }

  Future<void> loadLatest() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchLatestForCurrentUser);
  }

  Future<bool> submit({
    required XFile identityImage,
    required XFile medicalImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.submit(
        identityImage: identityImage,
        medicalImage: medicalImage,
      );
      await loadLatest();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class AdminVerificationNotifier
    extends StateNotifier<AsyncValue<List<AccountVerificationRequestEntity>>> {
  final AccountVerificationRepository _repository;

  AdminVerificationNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchPendingRequests);
  }

  Future<String> signedUrl(String path) {
    return _repository.createSignedUrl(path);
  }

  Future<bool> review({
    required AccountVerificationRequestEntity request,
    required bool approved,
    String? note,
  }) async {
    try {
      await _repository.review(
        request: request,
        approved: approved,
        note: note,
      );
      await fetch();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
