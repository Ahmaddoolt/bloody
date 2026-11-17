import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';
import '../domain/entities/account_verification_request_entity.dart';

class AccountVerificationRepository {
  final SupabaseClient _supabase;

  AccountVerificationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<AccountVerificationRequestEntity?> fetchLatestForCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('account_verification_requests')
          .select()
          .eq('donor_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return AccountVerificationRequestEntity.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'AccountVerificationRepository.fetchLatestForCurrentUser',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<void> submit({
    required XFile identityImage,
    required XFile medicalImage,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Missing user session');

    final folder = DateTime.now().millisecondsSinceEpoch.toString();
    final identityPath = await _uploadImage(
      file: identityImage,
      path: '$userId/$folder/identity_${identityImage.name}',
    );
    final medicalPath = await _uploadImage(
      file: medicalImage,
      path: '$userId/$folder/medical_${medicalImage.name}',
    );

    await _supabase.from('account_verification_requests').insert({
      'donor_id': userId,
      'identity_document_path': identityPath,
      'medical_document_path': medicalPath,
      'status': 'pending',
    });

    await _supabase
        .from('profiles')
        .update({'verification_status': 'pending'}).eq('id', userId);
  }

  Future<List<AccountVerificationRequestEntity>> fetchPendingRequests() async {
    try {
      final response = await _supabase
          .from('account_verification_requests')
          .select(
            '''
              *,
              donor:profiles!account_verification_requests_donor_id_fkey(
                username,
                email,
                phone,
                blood_type,
                city
              )
            ''',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => AccountVerificationRequestEntity.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'AccountVerificationRepository.fetchPendingRequests',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<String> createSignedUrl(String path) {
    return _supabase.storage
        .from('verification-documents')
        .createSignedUrl(path, 600);
  }

  Future<void> review({
    required AccountVerificationRequestEntity request,
    required bool approved,
    String? note,
  }) async {
    final status = approved ? 'approved' : 'rejected';
    final profileStatus = approved ? 'verified' : 'rejected';

    await _supabase.from('account_verification_requests').update({
      'status': status,
      'admin_note': note,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', request.id);

    await _supabase.from('profiles').update({
      'verification_status': profileStatus,
      'verified_at': approved ? DateTime.now().toIso8601String() : null,
    }).eq('id', request.donorId);
  }

  Future<String> _uploadImage({
    required XFile file,
    required String path,
  }) async {
    final Uint8List bytes = await file.readAsBytes();

    await _supabase.storage.from('verification-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(file.name),
            upsert: true,
          ),
        );

    return path;
  }

  String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
