# Fix Donor Dashboard Issues

## Issues Identified

### 1. **Critical Bug: 15 Items → 0 on Refresh** 🐛
**Root Cause**: In `receiver_list_provider.dart`, when `loadMore: false`, the code uses `state.offset` which may not be 0 from previous loads.

**Current buggy code**:
```dart
Future<void> fetchReceivers({..., bool loadMore = false}) async {
  ...
  final receivers = await _service.getCompatibleReceivers(
    offset: state.offset,  // BUG: Uses current offset (may be 50+)
    limit: state.limit,
    ...
  );
}
```

**Fix**: Reset offset to 0 when `loadMore: false`:
```dart
final offset = loadMore ? state.offset : 0;
final receivers = await _service.getCompatibleReceivers(
  offset: offset,
  ...
);

// Update state with new offset
state = state.copyWith(
  items: newItems,
  offset: loadMore ? state.offset + state.limit : state.limit,
  ...
);
```

### 2. **Change Pagination from 50 to 20** 📄
**File**: `receiver_list_provider.dart` line 31

Change:
```dart
this.limit = 50,  // TO: this.limit = 20,
```

### 3. **Fix "Unknown" Translation** 🌍
**Issue**: `'unknown'.tr()` in receiver_card.dart might show raw text if context not ready

**Current**:
```dart
final username = userData['username'] ?? 'unknown'.tr();
```

**Fix**: Use fallback with tr():
```dart
final username = userData['username']?.toString().isNotEmpty == true 
    ? userData['username'] 
    : 'unknown'.tr();
```

Also check translations exist:
- `assets/en.json`: `"unknown": "Unknown"` ✅
- `assets/ar.json`: `"unknown": "غير معروف"` ✅

### 4. **Verify Pagination Works** ✅
- Load first 20 items
- Scroll to bottom → load next 20
- Pull to refresh → reset to first 20

## Files to Modify

1. `lib/features/donor/dashboard/presentation/providers/receiver_list_provider.dart`
   - Fix offset bug
   - Change limit from 50 to 20

2. `lib/features/donor/dashboard/presentation/widgets/receiver_card.dart`
   - Fix username null/empty handling

## Testing Checklist

- [ ] Initial load shows 20 items
- [ ] Scroll loads more items (pagination)
- [ ] Pull-to-refresh resets to 20 items (not 0)
- [ ] "Unknown" shows translated text
- [ ] Card design remains perfect

## Notes
- User likes the current card design ✓
- Keep all existing styling
- Just fix the data loading bugs
