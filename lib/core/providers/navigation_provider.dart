import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for bottom navigation current index
final navigationIndexProvider = StateProvider<int>((ref) => 0);
