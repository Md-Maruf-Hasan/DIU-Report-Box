# DIU Report Box

DIU Report Box is a mobile application for university students at Daffodil International University (DIU).

## Key Features

1. **Authentication**:
   - University email (`@diu.edu.bd`) restriction on client & Cloud Functions.
   - Email verification enforcement gate.
2. **Lost & Found**:
   - Feed with category and status filter (All / Lost / Found / Resolved).
   - Up to 3 photos, location, contact method, resolve/delete actions.
3. **General Q&A / Discussion**:
   - Post with profile or anonymously.
   - Anonymous author identity is protected server-side in an admin-only collection.
   - Comments with anonymous toggle, like count, sorting.
4. **Specific Report (Maintenance Routing)**:
   - Direct student reports for campus facilities (Electrical, IT, Furniture, Plumbing, AC/Light, etc.).
   - Automatic SMS dispatch to designated department maintenance staff using SMS gateways.
   - English GSM <= 160 char formatting with human-readable reference numbers (e.g., `R-1042`).
   - Anti-spam rate limiting (5 reports per 24 hours per student, enforced server-side).
   - Real-time status tracking (`submitted -> sms_sent -> resolved`) and FCM push notifications.
5. **Resource Materials**:
   - 3 sub-sections: Previous Questions (Image/PDF), Notes (Image/PDF/Link), Others (Image/PDF/Link).
   - Attachment validation (PDF <= 10MB, Image <= 5MB).
   - Department, course code, and semester filtering.
6. **Admin Moderation & Management**:
   - Review reported content.
   - Manage department rooms and maintenance contacts.
   - Monitor failed SMS delivery and manually trigger retries.

---

## Tech Stack

- **Framework**: Flutter (Dart null-safety)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: `go_router`
- **Backend**: Firebase Auth, Cloud Firestore, Supabase Storage, Cloud Functions (TypeScript)
- **SMS Gateway**: SSL Wireless / BulkSMSBD / Alpha SMS / Sandbox Mock
- **Push Notifications**: Firebase Cloud Messaging (FCM)

---

## Setup & Local Development

### 1. Prerequisites
- **Flutter SDK**: Installed and added to PATH (`C:\flutter\src\flutter\bin`)
- **Node.js**: v20+ with npm
- **Firebase CLI**: `npm install -g firebase-tools`
- **Java**: JDK 17+ (for Firebase Emulators)

### 2. Configure Firebase
1. Create a Firebase project in the Firebase Console.
2. Enable **Authentication** (Email/Password).
3. Enable **Cloud Firestore**.
4. Run FlutterFire CLI:
   ```bash
   flutterfire configure --project=<your-firebase-project-id>
   ```

### 3. Configure Supabase Storage
1. Create a Supabase project.
2. Create a public storage bucket named `app-files`.
3. Run the app with the following defines:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```
4. Uploaded files use `lostFound/{postId}`, `qa/{postId}`, `reports/{reportId}`, and `resources/{resourceId}` paths.

### 4. Running Firebase Local Emulators
To test Firebase services locally (Firestore, Auth, Functions):
```bash
firebase emulators:start
```
The emulator UI will be available at `http://localhost:4000`.

### 5. Install Cloud Functions Dependencies & Build
```bash
cd functions
npm install
npm run build
```

### 6. Run Security Rules Unit Tests
```bash
cd functions
npm test
```

### 7. Seed Initial Departments, Rooms & Maintenance Contacts
With the emulators running:
```bash
# Windows PowerShell
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
node scripts/seed_departments.js
```

### 8. Grant Admin Role
To promote a registered university email to an admin:
```bash
node scripts/set_admin_role.js admin@diu.edu.bd admin
```

### 9. Run the Flutter App
```bash
flutter pub get
flutter run
```

To preview the main UI without connecting Firebase, run:
```bash
flutter run -d chrome --dart-define=DEMO_PREVIEW=true
```
This mode uses sample data, skips Firebase initialization, and disables backend actions.

---

## Project Structure
```
lib/
  main.dart
  app/            # App routes, theme, constants
  core/           # Utilities, validators, shared widgets, error handling
  features/
    auth/         # Sign up, domain verification, login, password reset
    home/         # Navigation shell & 4 tabs
    lost_found/   # Feed, creation, resolution, filtering
    qa/           # Posts, comments, likes, anonymous posting
    reports/      # Submit maintenance report & My Reports tracker
    resources/    # Previous questions, notes, and attachments
    profile/      # User settings & my posts
    admin/        # Moderation, maintenance contacts, SMS retry
functions/        # TypeScript Cloud Functions
firestore.rules   # Security rules
DECISIONS.md      # Architecture log
```
