# Feature Specification: Donor Trust, Support, and AI Blood Assistant

**Feature Branch**: `001-donor-trust-support-ai`  
**Created**: 2026-05-25  
**Status**: Approved  
**Input**: Donors should see receiver situations, signup safety instructions, admin banned accounts, fixed center filtering/order, support contact, donor account verification, and a Gemini Flash health/blood chatbot.

## User Scenarios & Testing

### User Story 1 - Donors Understand Receiver Situations (Priority: P1)

Donors can scan receivers and open a receiver card to read the receiver's situation before deciding to call.

**Independent Test**: A receiver with a saved situation appears on the donor dashboard with a preview and a detail sheet.

**Acceptance Scenarios**:

1. **Given** a receiver has a situation, **When** a compatible donor opens the receiver list, **Then** the card shows a preview.
2. **Given** a donor taps the card, **When** details open, **Then** the full situation, blood type, location, age, and call action are visible.

### User Story 2 - Safer Donor Signup and Verification (Priority: P1)

Donors see blood safety instructions before signing up and can request account verification from settings using identity/donor proof plus medical proof images.

**Independent Test**: A donor can view the testing instructions, submit both proof images, and see pending/approved/rejected status.

**Acceptance Scenarios**:

1. **Given** a user selects donor signup, **When** the donor safety dialog opens, **Then** it names the required health and blood screening checks.
2. **Given** a donor submits proof images, **When** admin approves the request, **Then** receivers see the donor as verified.

### User Story 3 - Admin Trust Controls (Priority: P1)

Admins can ban/unban user accounts and approve/reject donor verification requests.

**Independent Test**: Admin can ban a user, the user is prevented from normal app access, and unbanning restores access.

**Acceptance Scenarios**:

1. **Given** an admin bans an account, **When** the banned user signs in, **Then** they are signed out and shown an account forbidden message.
2. **Given** an admin approves a verification request, **When** receivers view donors, **Then** the approved donor has a verified badge.

### User Story 4 - Centers and Support Are Easier to Use (Priority: P2)

Changing region filters updates centers correctly, donors see highest-need centers first, and users can contact support from settings.

**Independent Test**: Admin city filter can switch and clear; shared center list sorts by shortage; settings opens support email.

### User Story 5 - AI Blood Health Assistant (Priority: P2)

Users can chat with a Gemini Flash assistant that answers only blood and health education questions.

**Independent Test**: A blood donation question receives an answer, while an off-topic question is refused.

## Requirements

### Functional Requirements

- **FR-001**: Donor receiver cards MUST show receiver situation preview when available and open a detail sheet on tap.
- **FR-002**: Donor signup MUST show eligibility and test guidance before selecting donor account type.
- **FR-003**: Donors MUST be able to submit account verification requests with identity/donor proof and medical proof images.
- **FR-004**: Admins MUST approve or reject verification requests.
- **FR-005**: Receiver donor lists MUST show whether each donor is verified.
- **FR-006**: Admins MUST ban and unban accounts with an optional reason.
- **FR-007**: Forbidden accounts MUST be prevented from normal app access and excluded from discovery/notification queries.
- **FR-008**: Donor-facing center lists MUST prioritize centers with highest blood need.
- **FR-009**: Admin center region filter MUST update and clear correctly.
- **FR-010**: Settings MUST expose support email contact.
- **FR-011**: The chatbot MUST only answer blood and health education questions and refuse unrelated prompts.

### Key Entities

- **Account Verification Request**: Donor request with status, submitted proof image paths, admin reviewer, and review note.
- **Forbidden Account State**: Profile moderation fields controlling access and discovery visibility.
- **AI Chat Message**: Local session message with role, text, and timestamp.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Donor can open receiver situation details in two taps or fewer.
- **SC-002**: Donor verification request can be submitted with both required images and reviewed by admin.
- **SC-003**: Forbidden users are excluded from donor/receiver discovery after refresh.
- **SC-004**: Off-topic chatbot prompts receive a refusal instead of domain advice.
- **SC-005**: `flutter analyze` and relevant tests complete with no new feature-related errors.

## Assumptions

- Super admin remains `adminbloody2026@gmail.com`.
- Support email is `support@bloody.app`.
- AI answers are educational and include emergency/doctor guidance where appropriate.
- Gemini is called server-side from Supabase Edge Functions using `GEMINI_API_KEY`.
