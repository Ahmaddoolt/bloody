# Auth Pages Fixes Plan

**Status**: COMPLETED ✓

## Overview
Fix three issues in the auth system:
1. Error messages showing raw exceptions instead of user-friendly text
2. Onboarding showing every time after logout (should only show once)
3. Add colored Supabase logging following nano printing skill

## Changes Required

### 1. Fix auth_error_mapper.dart
**File**: `lib/features/shared/auth/utils/auth_error_mapper.dart`
- Line 35: Change `return message;` to `return 'login_failed'.tr();`
- Add check for `user_already_exists` code to map to `auth_error_already_registered`

### 2. Fix auth_provider.dart signOut
**File**: `lib/features/shared/auth/presentation/providers/auth_provider.dart`
- Line 114-116: Preserve `hasSeenOnboarding` state when signing out
- Change from `state = const AuthStateEntity();` to preserve onboarding flag

### 3. Create ApiLogger utility
**New File**: `lib/core/utils/api_logger.dart`
- Create colored logging utility following nano printing skill
- Support for success (2xx), error (4xx/5xx), and network error logging
- ANSI color codes for beautiful console output

### 4. Update auth_repository_impl.dart
**File**: `lib/features/shared/auth/data/repositories/auth_repository_impl.dart`
- Import ApiLogger
- Add colored logging for all Supabase operations:
  - signIn: Log auth response
  - signUp: Log auth response and profile creation
  - signOut: Log operation
  - checkCurrentSession: Log session check

## Testing
- Verify error messages show translated text, not raw exceptions
- Verify onboarding only appears on first app launch
- Verify Supabase calls are logged with colors in debug console
