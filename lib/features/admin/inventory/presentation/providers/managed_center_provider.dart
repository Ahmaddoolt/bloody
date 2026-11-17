import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The center this user manages (`centers.admin_id == current uid`), or `null`
/// if this user is not assigned to any center.
///
/// SELECT on `centers` is public — no RLS issue for the read.
final managedCenterProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  return supabase
      .from('centers')
      .select()
      .eq('admin_id', userId)
      .maybeSingle();
});
