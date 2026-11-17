# Implementation Plan: Donor Trust, Support, and AI Blood Assistant

**Branch**: `001-donor-trust-support-ai` | **Date**: 2026-05-25 | **Spec**: `specs/001-donor-trust-support-ai/spec.md`

## Summary

Add trust and safety flows around blood donation: receiver situations for donors, donor verification, admin moderation, better center ordering/filtering, support contact, and a server-side Gemini Flash chatbot restricted to blood and health topics.

## Technical Context

**Language/Version**: Flutter / Dart SDK `^3.0.0`, Supabase Edge Functions on Deno  
**Primary Dependencies**: Flutter, Riverpod, Supabase, Easy Localization, url_launcher, image_picker  
**Storage**: Supabase Postgres and private Supabase Storage bucket  
**Testing**: `flutter test`, `flutter analyze`, function smoke tests  
**Target Platform**: iOS first, Android second  
**Project Type**: Mobile app with Supabase backend  
**Constraints**: Sensitive health/identity data, no off-topic AI answers, no forbidden users in discovery  
**Scale/Scope**: Existing donor, receiver, admin, settings, centers, and auth flows

## Constitution Check

- Pass: Feature-first actor-aware structure.
- Pass: Riverpod for stateful UI.
- Pass: Supabase isolated to data/providers/edge functions.
- Pass: New screens/providers added instead of expanding oversized files where possible.

## Project Structure

```text
lib/
  core/constants/
  features/admin/
  features/donor/
  features/receiver/
  features/shared/
supabase/
  migrations/
  functions/
specs/001-donor-trust-support-ai/
```

**Structure Decision**: Add new admin/shared features for moderation, verification, and AI chat; touch existing large screens only for navigation entry points.

## Implementation Notes

- Use `profiles.verification_status` as the public donor verification signal.
- Store verification images in `account-verifications/<user-id>/<request-id>/`.
- Use `profiles.is_forbidden` and related moderation fields for ban/unban.
- Gemini model is `gemini-2.5-flash`; server prompt restricts answers to blood donation, blood safety, donor eligibility, anemia/iron, and general health education.
