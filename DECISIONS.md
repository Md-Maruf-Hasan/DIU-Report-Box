# DIU Report Box — Architecture & Technical Decisions

This document records architectural, technical, and implementation decisions made in accordance with the project guidelines.

---

## 1. Project Directory & Workspace
- **Decision**: The project is located at `C:\Users\Maruf\.gemini\antigravity\scratch\diu_report_box`.
- **Reasoning**: In accordance with the system guidelines when no active workspace is set, all project files are kept in the designated scratch directory.

---

## 2. University Email Validation & Domain Restriction
- **Decision**: `ALLOWED_EMAIL_DOMAIN` default is set to `diu.edu.bd`.
- **Validation**:
  - Client-side validation prevents submission with invalid domains in the signup form.
  - Cloud Functions enforce domain restriction on `beforeUserCreated` (blocking auth function) and as fallback on `onCreate` (deleting account if invalid).
  - Students must verify email before accessing app features (`emailVerified == true`).

---

## 3. Anonymous Q&A Implementation
- **Decision**:
  - The public `qaPosts/{postId}` and `comments/{commentId}` documents store `isAnonymous: true`, `authorUid: null`, and `authorName: null`.
  - Author identity is recorded in admin-only collections: `postAuthors/{postId}` (`{ authorUid, createdAt }`) and `commentAuthors/{commentId}` (`{ authorUid, createdAt }`).
  - Creation of anonymous posts and comments is handled via Cloud Functions HTTPS Callables (`createAnonymousPost`, `createAnonymousComment`).
  - Deletion/editing of anonymous posts by their author is handled via a secure Cloud Function callable (`deleteAnonymousPost`, `deleteAnonymousComment`) that validates `request.auth.uid == postAuthors.authorUid`.
  - Firestore Security Rules completely block client read/write to `postAuthors` and `commentAuthors` for non-admins.

---

## 4. Specific Report Routing & SMS Gateway Integration
- **Decision**:
  - Report creation goes through the `createReport` Cloud Function callable. This enforces the 5 reports per 24-hour rate limit per student and assigns a sequential human-readable reference number (`R-1001`, `R-1002`, etc.) via a Firestore transaction counter doc (`metadata/reportCounter`).
  - SMS gateway integration supports Bangladesh SMS providers (SSL Wireless, BulkSMSBD, Alpha SMS) via an abstract SMS provider interface with a mock/sandbox provider for local testing and emulator mode.
  - SMS message format is strictly English GSM (<= 160 characters):
    `DIU Report: [Dept] Room [RoomNo] - [Category]. [Description]. Ref: [RefNo]`
  - Cloud Function `onReportCreated` attempts delivery. If delivery fails, status is set to `failed` and queued for scheduled retry (`retryFailedSms`, max 3 attempts with exponential backoff).
  - Maintenance phone numbers are stored in `departments/{departmentId}/maintenanceContacts` and restricted to Admin-only read/write in security rules. Students can never access this collection.

---

## 5. Security Rules & Role Management
- **Decision**:
  - Roles (`student`, `admin`) are stored as Firebase Auth Custom Claims (`request.auth.token.role`).
  - Firestore Security Rules enforce:
    1. `request.auth != null && request.auth.token.email_verified == true` for all app access.
    2. Admin role check: `request.auth.token.role == 'admin'`.
    3. Private reports: `resource.data.reporterUid == request.auth.uid || request.auth.token.role == 'admin'`.
    4. Maintenance contacts: only `admin` can read/write.
    5. Anonymous author collections: only `admin` can read; no direct client writes.

---

## 6. Resource Materials Moderation & Attachment Types
- **Decision**:
  - Config flag `RESOURCE_REQUIRES_APPROVAL` defaults to `false` (immediate availability) but can be set to `true` to require admin approval before appearing in public queries.
  - Storage path convention:
    - `resources/{resourceId}/{fileName}`
    - Size limits: Image <= 5 MB, PDF <= 10 MB.
  - Mime types and file extensions are strictly validated before upload and in Storage Security Rules.

---

## 7. Deferred / Future Features (Out of Scope for Initial Release)
- In-app live chat between students and finders.
- Report heat map / statistical analytics dashboard per department.
- Resource upvoting and rating system.
- Push notification webhooks for staff.
- Multi-language (Bangla UI localization).
- iOS production release builds.
