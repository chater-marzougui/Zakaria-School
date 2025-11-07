# Quick Setup Guide - École de Conduite Zakaria

## Prerequisites
- Flutter SDK ^3.9.2 installed
- Firebase account created
- Android Studio / Xcode (for mobile development)
- Git

## Step 1: Clone and Install Dependencies

```bash
git clone <repository-url>
cd Zakaria-School
flutter pub get
```

## Step 2: Firebase Setup

### 2.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it (e.g., "Ecole-Zakaria")
4. Disable Google Analytics (optional)
5. Create project

### 2.2 Enable Authentication
1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

### 2.3 Create Firestore Database
1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in production mode"
4. Select location closest to your users
5. Click "Enable"

### 2.4 Set Firestore Security Rules
Go to Firestore → Rules and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /candidates/{candidateId} {
      allow read, write: if request.auth != null;
    }
    
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2.5 Create Firestore Indexes
Go to Firestore → Indexes → Composite and create:

1. Collection: `sessions`
   - Field: `date` (Ascending)
   - Field: `candidate_id` (Ascending)

2. Collection: `sessions`
   - Field: `candidate_id` (Ascending)
   - Field: `date` (Descending)

3. Collection: `sessions`
   - Field: `candidate_id` (Ascending)
   - Field: `status` (Ascending)
   - Field: `date` (Ascending)

### 2.6 Configure FlutterFire

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter project
flutterfire configure
```

Select your Firebase project and the platforms you want to support (iOS/Android).

This will create `firebase_options.dart` automatically.

## Step 3: Create Initial User

Since there's no registration flow, create a test user manually:

1. Go to Firebase Console → Authentication → Users
2. Click "Add user"
3. Enter email: `test@example.com`
4. Enter password: `Test1234`
5. Click "Add user"

Then, add user document in Firestore:

1. Go to Firestore Database
2. Create collection: `users`
3. Add document with ID matching the user's UID from Authentication
4. Add fields:
   ```json
   {
     "uid": "<user-uid>",
     "email": "test@example.com",
     "displayName": "Test Instructor",
     "firstName": "Test",
     "lastName": "Instructor",
     "phoneNumber": "+21612345678",
     "createdAt": <Timestamp>
   }
   ```

## Step 4: Add Sample Data (Optional)

Create a test candidate in Firestore:

Collection: `candidates`
Document ID: Auto
Fields:
```json
{
  "name": "Mohamed Ben Ahmed",
  "phone": "+21698765432",
  "start_date": <Timestamp>,
  "theory_passed": false,
  "total_paid_hours": 30,
  "total_taken_hours": 15,
  "notes": "Candidate notes here",
  "assigned_instructor": "Test Instructor",
  "status": "active"
}
```

Create a test session:

Collection: `sessions`
Document ID: Auto
Fields:
```json
{
  "candidate_id": "<candidate-doc-id>",
  "instructor_id": "<user-uid>",
  "date": <Timestamp for today>,
  "start_time": "09:00",
  "end_time": "10:00",
  "status": "scheduled",
  "note": "",
  "payment_status": "unpaid"
}
```

## Step 5: Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For web (testing only)
flutter run -d chrome
```

## Step 6: Login

Use the credentials you created:
- Email: `test@example.com`
- Password: `Test1234`

## Troubleshooting

### "Firebase not initialized" error
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists
- Rebuild the app completely

### "Permission denied" in Firestore
- Check Firestore security rules
- Make sure user is authenticated
- Verify rules are published

### "Collection not found" error
- Create at least one document in each collection manually
- Firestore collections don't exist until they have data

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Translation issues
```bash
flutter gen-l10n
```

## App Structure Quick Reference

### Main Navigation (Bottom Bar)
1. **Dashboard** - Today's sessions and quick stats
2. **Calendar** - Weekly view of all sessions
3. **Candidates** - List all candidates, add new ones
4. **Settings** - Language, theme, export data, logout

### Key Features
- **Add Candidate**: Candidates tab → FAB (+) button
- **Add Session**: Dashboard or Calendar → FAB (+) button
- **View Details**: Tap any candidate or session
- **Mark Payment**: Candidate Details → Payments tab → "Mark Payment"
- **Export Data**: Settings → Export Data
- **Switch Language**: Settings → Language dropdown
- **Toggle Theme**: Settings → Theme Mode dropdown

## Default Login Credentials

After setup, you should have:
- Email: `test@example.com`
- Password: `Test1234`

## Next Steps

1. Customize the app name and icon
2. Add more instructors in Firebase Authentication + Firestore
3. Import candidate data if you have existing records
4. Configure push notifications (optional)
5. Set up backup schedules
6. Review IMPLEMENTATION.md for detailed documentation

## Support

For detailed implementation information, see:
- `IMPLEMENTATION.md` - Complete documentation
- `README.md` - Project overview
- Firebase Console - For backend management

## Production Deployment

Before deploying to production:
1. Review Firestore security rules thoroughly
2. Set up proper authentication
3. Configure app signing (Android/iOS)
4. Test on physical devices
5. Enable Crashlytics for monitoring
6. Set up proper backup procedures

---

**Happy Coding! 🚗💨**
