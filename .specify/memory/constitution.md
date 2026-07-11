# Bloody App Constitution

## Core Principles

### I. Flutter Clean Architecture
The app uses feature-first Clean Architecture. Domain code stays pure Dart, data code owns Supabase/API details, and presentation code owns widgets and Riverpod state. Actor-specific behavior belongs under `features/donor`, `features/receiver`, or `features/admin`; shared behavior belongs under `features/shared` or `core`.

### II. Riverpod State Management
All async app state flows through Riverpod providers and exposes loading, data, and error states. UI reads providers with `ref.watch`, invokes actions with `ref.read` in callbacks, and never calls Supabase directly for new business flows.

### III. Apple-Style Responsive UI
Top-level screens use `SafeArea`, compact native-feeling controls, accessible touch targets, and responsive constraints for phone and tablet widths. UI uses `AppColors`, `AppTypography`, and `AppSpacing` instead of hardcoded styling whenever those tokens cover the need.

### IV. Safety, Trust, and Privacy
Blood, health, identity, and verification data is treated as sensitive. Admin-only actions require explicit screens, user-facing AI must stay limited to blood and health education, and forbidden users must not appear in discovery or notification flows.

### V. Verification Before Completion
Every feature implementation must be formatted, statically analyzed, and tested where practical. Failures must be reported plainly with file/context. No `print()` is allowed in app code; use the existing logger.

## Stack and Constraints

- Flutter mobile app, iOS first and Android second.
- Supabase for auth, database, storage, and Edge Functions.
- Riverpod for state management.
- Easy Localization for user-facing copy in `assets/en.json` and `assets/ar.json`.
- Keep diffs scoped and split new screens/providers instead of expanding oversized files.

## Development Workflow

- Specs live under `specs/<number>-<feature>/`.
- Mutating work starts only after an approved plan.
- Update feature tasks when implementation work is completed.
- Run `dart format`, `flutter analyze`, and relevant tests before marking work complete.

## Governance

This constitution overrides generic defaults when repo-specific architecture or safety rules conflict. Changes require a short rationale in the related feature plan.

**Version**: 1.0.0 | **Ratified**: 2026-05-25 | **Last Amended**: 2026-05-25
