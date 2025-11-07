# Zakaria Driving School - Implementation Documentation

## Project Overview

École de Conduite Zakaria is a comprehensive driving school management application built with Flutter and Firebase. The app helps instructors and theory teachers manage candidates, schedule driving sessions, track payments, and maintain detailed records.

### Tech Stack
- **Frontend**: Flutter (SDK ^3.9.2)
- **Backend**: Firebase (Firestore, Auth)
- **State Management**: StatefulWidget with StreamBuilder for real-time updates
- **Localization**: flutter_localizations with support for English, French, and Arabic
- **Theme**: Material Design 3 with light/dark mode support

### Key Features
1. **User Authentication**: Email/password login (no registration - users pre-configured by admin)
2. **Dashboard**: Overview of today's sessions, upcoming sessions, and unpaid summary
3. **Calendar View**: Weekly calendar with color-coded session blocks
4. **Candidate Management**: Full CRUD operations with detailed profiles
5. **Session Management**: Schedule, track, and manage driving sessions
6. **Payment Tracking**: Monitor paid/unpaid sessions per candidate
7. **Data Export**: Export candidates and sessions to CSV
8. **Multi-language**: EN, FR, AR support
9. **Dark Mode**: Full theme support
10. **Communication**: SMS, WhatsApp, and call integration

---

## Current Implementation Details

### 1. Data Models

#### Candidate Model (`lib/models/candidate_model.dart`)
```dart
class Candidate {
  final String id;
  final String name;
  final String phone;
  final DateTime startDate;
  final bool theoryPassed;
  final double totalPaidHours;
  final double totalTakenHours;
  final String notes;
  final String assignedInstructor;
  final String status; // 'active', 'graduated', 'inactive'
  
  // Computed properties:
  double get progressPercentage;
  double get remainingHours;
}
```

**Firestore Collection**: `/candidates`
- Document fields match the model properties
- Uses Timestamp for dates
- Indexed on `name` for efficient queries

#### Session Model (`lib/models/session_model.dart`)
```dart
class Session {
  final String id;
  final String candidateId;
  final String instructorId;
  final DateTime date;
  final String startTime; // Format: "HH:mm"
  final String endTime;
  final String status; // 'scheduled', 'done', 'missed', 'rescheduled'
  final String note;
  final String paymentStatus; // 'paid', 'unpaid'
  
  // Computed property:
  double get durationInHours;
}
```

**Firestore Collection**: `/sessions`
- Document fields match the model properties
- Indexed on `date`, `candidate_id`, and `status`
- Uses Timestamp for dates

#### User Model (`lib/models/user_model.dart`)
```dart
class User {
  final String uid;
  final String displayName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime birthdate;
  final String gender;
  final DateTime createdAt;
  final String profileImage;
  final String? role;
}
```

**Firestore Collection**: `/users`
- Stores instructor/teacher information
- No RBAC - all users have equal access

---

### 2. Screen Implementations

#### Dashboard Screen (`lib/screens/dashboard_screen.dart`)
**Purpose**: Main overview screen showing key metrics and upcoming activities

**Features**:
- Summary cards: Today's sessions count, Unpaid hours total
- Today's sessions list with status indicators
- Upcoming 5 sessions preview
- FloatingActionButton to add new session
- Pull-to-refresh support
- Real-time updates via StreamBuilder

**Status Colors**:
- 🟢 Green: Scheduled
- 🔵 Blue: Done
- 🟠 Orange: Rescheduled
- 🔴 Red: Missed

#### Calendar Screen (`lib/screens/calendar_screen.dart`) **ENHANCED**
**Purpose**: Weekly calendar view for session visualization with advanced features

**Features**:
- Week navigation (previous/next/today)
- 7-day grid (Monday-Sunday)
- **15-minute time intervals** from 8:00 to 20:00 (8:00, 8:15, 8:30, 8:45, etc.)
- **Side-by-side session display** when multiple candidates have overlapping times
- Sessions span multiple rows based on their duration
- **Today column highlighted** with background color
- Color-coded session blocks by status
- Tap to view session details with edit option
- Legend for status colors
- Responsive horizontal/vertical scrolling

**Implementation Details**:
- Time slots stored as minutes since midnight for precise calculations
- Sessions displayed as connected blocks across their full duration
- Only first time slot of each session shows candidate name and time
- Automatic cell width adjustment when sessions overlap
- Sessions filtered by week start/end dates
- Firestore query optimized with date range filters

**Grid Layout**:
- Time column: 70px width
- Day columns: 150px width each (auto-splits for overlapping sessions)
- Row height: 40px per 15-minute interval
- Borders for clear visual separation

#### Candidates List Screen (`lib/screens/candidates_list_screen.dart`)
**Purpose**: Browse and search all candidates

**Features**:
- Real-time candidate list
- Search by name or phone
- Progress bars showing completion percentage
- Remaining hours display
- Next session preview per candidate
- FloatingActionButton to add new candidate
- Add candidate dialog with name and phone fields

**Search Implementation**:
- Case-insensitive search
- Filters on name and phone
- Instant results as you type

#### Candidate Detail Screen (`lib/screens/candidate_detail_screen.dart`)
**Purpose**: Comprehensive view of a single candidate

**Features**: 3 tabs with detailed information

**Tab 1 - Info**:
- All candidate information displayed as cards
- Editable notes field (auto-saves to Firestore)
- Contact actions: Phone, SMS, WhatsApp
- Status indicators

**Tab 2 - Schedule**:
- All sessions for this candidate
- Ordered by date (newest first)
- Session status and payment indicators
- Tap to view details

**Tab 3 - Payments**:
- Payment summary card (paid vs unpaid)
- List of all sessions with payment status
- "Mark as Paid" button for unpaid sessions
- Updates Firestore immediately

**Communication Integration**:
- Phone: Uses `tel:` URI scheme
- SMS: Uses `sms:` URI scheme
- WhatsApp: Uses `https://wa.me/` with external app launch

#### Add/Edit Session Screen (`lib/screens/add_session_screen.dart`) **ENHANCED**
**Purpose**: Create or modify sessions with validation

**Features**:
- Form with validation
- Candidate dropdown (populated from Firestore)
- Instructor dropdown (populated from users)
- Date picker
- **Custom time pickers with 15-minute intervals** (00, 15, 30, 45)
- **Overlap validation**: Prevents double-booking for the same candidate
- Duration calculation and preview
- Status dropdown (scheduled/done/missed/rescheduled)
- Payment status dropdown (paid/unpaid)
- Notes field
- Save button with validation
- Delete button (edit mode only)
- Confirmation dialog for deletion

**Time Picker Enhancement**:
- Custom dialog with hour and minute dropdowns
- Minutes restricted to 15-minute intervals (00, 15, 30, 45)
- Live preview of selected time
- User-friendly interface for quick selection

**Validation Features**:
- Uses DatabaseService for overlap checking
- Clear error messages displayed when conflicts detected
- Shows duration of 4+ seconds for user to read the error
- Validation on both create and update operations

**Auto-Update Logic**:
- When session marked as "done", automatically updates candidate's `total_taken_hours`
- Duration calculated from start/end times

#### Developer Screen (`lib/screens/settings_screens/developer_screen.dart`) **NEW**
**Purpose**: Testing and database management tools

**Features**:
- Real-time database statistics dashboard
- Three statistics cards:
  - **Candidates**: Total, Active, Graduated, Inactive
  - **Sessions**: Total, Scheduled, Done, Missed, Rescheduled
  - **Payments**: Paid vs Unpaid sessions
- **Generate Test Data**: Create 21 candidates and 180 sessions
- **Custom Data Generation**: Specify exact counts for candidates/sessions
- **Delete All Data**: Clear all candidates and sessions (users unaffected)
- Refresh button to update statistics
- Warning banner for caution

**Safety Features**:
- Confirmation dialogs for destructive operations
- Color-coded buttons (red for dangerous actions)
- User data (collection: `users`) is never touched
- Success/error feedback with snackbars

**Usage**:
- Accessible from Settings → Developer Tools
- Ideal for testing scheduling conflicts
- Generate realistic test data with Tunisian names
- Quick cleanup between test scenarios

#### Settings Screen (`lib/screens/settings_screens/settings_page.dart`) **UPDATED**
**Purpose**: App configuration and data management

**Features**:
- Language selector (EN/FR/AR) - updates immediately
- Theme mode selector (light/dark) - updates immediately
- Notifications toggle
- Export Data button - exports to CSV
- **Developer Tools** - link to developer screen
- About dialog with app version and developer info
- Logout button with confirmation

**Export Functionality**:
- Generates separate CSV files for candidates and sessions
- Saves to device's documents directory
- Shows file paths in success message
- Includes all fields with proper escaping

---

### 3. Services

#### Database Service (`lib/services/db_service.dart`) **NEW**
**Purpose**: Centralized database operations with validation and error handling

**Candidate Operations**:
- `createCandidate(Candidate)`: Create a new candidate
- `getCandidate(id)`: Get single candidate by ID
- `getAllCandidates()`: Get all candidates
- `updateCandidate(id, updates)`: Update candidate fields
- `deleteCandidate(id)`: Delete candidate and all their sessions
- `deleteAllCandidates()`: Clear all candidates and sessions

**Session Operations**:
- `createSession(Session, checkOverlap)`: Create session with optional overlap validation
- `getSession(id)`: Get single session by ID
- `getCandidateSessions(candidateId)`: Get all sessions for a candidate
- `getAllSessions()`: Get all sessions
- `getSessionsInDateRange(start, end)`: Query sessions by date range
- `updateSession(id, updates, checkOverlap)`: Update session with validation
- `deleteSession(id)`: Delete a session
- `deleteAllSessions()`: Clear all sessions

**Validation Features**:
- **Overlap Detection**: Automatically checks if a candidate already has a session at the same time
- Validates on both create and update operations
- Returns clear error messages when conflicts are detected
- Can be disabled by setting `checkOverlap: false`

**Statistics**:
- `getStatistics()`: Returns comprehensive database statistics
- Candidate counts by status (active, graduated, inactive)
- Session counts by status (scheduled, done, missed, rescheduled)
- Payment tracking (paid vs unpaid sessions)

#### Export Service (`lib/services/export_service.dart`)
**Purpose**: Generate CSV files for data backup/analysis

**Methods**:
- `exportCandidatesToCSV()`: Exports all candidates
- `exportSessionsToCSV()`: Exports all sessions
- `exportAllDataToCSV()`: Exports both

**CSV Format**:
- Properly escaped quotes in text fields
- Date format: dd/MM/yyyy
- Includes all model fields
- Filenames include timestamp: `candidates_20241105_143022.csv`

---

### 4. Widgets

#### Candidate Card (`lib/widgets/candidate_card.dart`)
- Reusable card component for candidate list items
- Shows avatar, name, phone, progress bar, and remaining hours
- Tap callback for navigation

#### Session Tile (`lib/widgets/session_tile.dart`)
- Reusable tile for session list items
- Color-coded status indicator
- Shows candidate name, date, time, duration
- Status and payment badges
- Tap callback for details

#### Custom Loading Screen (`lib/widgets/loading_screen.dart`)
- Consistent loading indicator across the app

#### Custom Snack Bar (`lib/widgets/snack_bar.dart`)
- Themed snack bar for user feedback
- Success/error variants

---

### 5. Navigation Structure

#### Bottom Navigation Bar (`lib/bottom_navbar.dart`)
4 main tabs:
1. **Dashboard** - Home screen
2. **Calendar** - Weekly view
3. **Candidates** - List and search
4. **Settings** - Configuration

**State Management**:
- Uses `Offstage` and `TickerMode` to preserve state across tab switches
- Prevents unnecessary rebuilds
- Smooth transitions

#### Routes (`lib/main.dart`)
- `/auth` - Login/Auth wrapper (initial route)
- `/add-session` - Add/Edit session screen

---

### 6. Localization

#### Supported Languages
- English (en)
- French (fr)
- Arabic (ar)

#### Translation Files
- `lib/l10n/app_en.arb` - 440+ keys
- `lib/l10n/app_fr.arb` - 440+ keys
- `lib/l10n/app_ar.arb` - 440+ keys

#### Key Translation Categories
- Navigation labels
- Form fields
- Action buttons
- Status values
- Error messages
- Success messages
- Dialog titles and content

**Usage Pattern**:
```
final t = AppLocalizations.of(context)!;
Text(t.dashboard); // Translated text
```

---

### 7. Theming

#### Light Theme
- Primary: Medium Green (#4CAF50)
- Secondary: Darker Green (#388E3C)
- Tertiary: Light Green (#81C784)
- Background: White
- Card: White70

#### Dark Theme
- Primary: Light Green (#81C784)
- Secondary: Medium Green (#4CAF50)
- Tertiary: Darker Green (#388E3C)
- Background: Dark Gray (#A5272424)
- Card: Dark (#1E1E1E)

**Theme Access Pattern**:
```
final theme = Theme.of(context);
color: theme.colorScheme.primary.withAlpha(128)
```

**Note**: Uses `withAlpha(int)` (0-255) instead of deprecated `withOpacity(double)` (0.0-1.0)

---

### 8. Firebase Configuration

#### Required Firebase Services
1. **Firebase Auth**: Email/password authentication
2. **Cloud Firestore**: NoSQL database for all data
3. **Firebase Storage**: (Optional) For future profile pictures

#### Firestore Security Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - read only for authenticated users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Candidates - full access for authenticated users
    match /candidates/{candidateId} {
      allow read, write: if request.auth != null;
    }
    
    // Sessions - full access for authenticated users
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Firestore Indexes (Required)
Create composite indexes for:
1. `sessions` collection:
   - `date` (Ascending) + `candidate_id` (Ascending)
   - `candidate_id` (Ascending) + `date` (Descending)
   - `candidate_id` (Ascending) + `status` (Ascending) + `date` (Ascending)

---

## Next Steps for Future Development

### High Priority (Recommended Next Sprint)

1. **Fix withValues to withAlpha Migration**
   - Update `login.dart` to use `withAlpha()` consistently
   - Search and replace all `withValues(alpha: X)` with `withAlpha(X)`
   - File locations: `lib/screens/user_management/login.dart`

2. **Add Firebase Options Configuration**
   - Create `firebase_options.dart` using FlutterFire CLI
   - Command: `flutterfire configure`
   - Add to gitignore (currently ignored)

3. **Test Complete User Flows**
   - Login → Dashboard → Add Candidate → Schedule Session → Mark Paid
   - Export data and verify CSV format
   - Test all 3 languages
   - Test dark/light theme switching

4. **Add Candidate Edit Functionality**
   - Implement `_showEditDialog()` in `candidate_detail_screen.dart`
   - Allow editing: name, phone, theory status, assigned instructor
   - Add form validation

5. **Enhanced Calendar Features**
   - Add month view option
   - Filter sessions by instructor
   - Add drag-and-drop for rescheduling (advanced)

### Medium Priority

6. **Statistics Dashboard**
   - Create `statistics_screen.dart`
   - Charts for:
     - Sessions per month
     - Payment collection rate
     - Candidate progress distribution
     - Instructor workload
   - Use `fl_chart` package

7. **Notifications**
   - Local notifications for upcoming sessions
   - Use `flutter_local_notifications` package
   - Schedule reminders 1 hour before sessions

8. **Offline Support**
   - Enable Firestore offline persistence
   - Add sync status indicator
   - Queue writes when offline

9. **Batch Operations**
   - Mark multiple sessions as paid
   - Bulk export filtered data
   - Mass reschedule sessions

10. **Advanced Search**
    - Filter candidates by status, instructor, theory passed
    - Filter sessions by date range, payment status
    - Saved search presets

### Low Priority / Nice to Have

11. **Profile Management**
    - Allow users to update their own profile
    - Add profile pictures
    - Use Firebase Storage

12. **Reports**
    - Monthly revenue report
    - Instructor performance report
    - Candidate progress report
    - Generate PDF reports

13. **Backup & Restore**
    - Scheduled automatic CSV exports
    - Import candidates from CSV
    - Cloud backup configuration

14. **Improved UI/UX**
    - Add animations for transitions
    - Skeleton loading screens
    - Empty state illustrations
    - Improved error handling with retry

15. **Testing**
    - Unit tests for models
    - Widget tests for screens
    - Integration tests for critical flows
    - Test coverage > 70%

---

## Development Guidelines

### Code Style
- Follow official Flutter style guide
- Use `dart format` before committing
- Run `flutter analyze` to check for issues

### Translation Updates
When adding new strings:
1. Add to `app_en.arb` with description
2. Translate to `app_fr.arb`
3. Translate to `app_ar.arb`
4. Run `flutter gen-l10n` to regenerate

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Keep messages concise and descriptive
- Reference issue numbers when applicable

### Testing Checklist
Before pushing:
- [ ] Code compiles without errors
- [ ] No analyzer warnings
- [ ] Tested on both light and dark themes
- [ ] Tested in all 3 languages
- [ ] Firebase queries are efficient
- [ ] No console errors in debug mode

---

## Known Issues / Limitations

1. **No User Registration Flow**: Users must be pre-created in Firestore by admin
2. **No RBAC**: All authenticated users have full access
3. **Calendar Limited to Week View**: No month/day views yet
4. **No Recurring Sessions**: Each session must be created manually
5. **No Payment Processing**: Just tracking, not actual payment integration
6. **CSV Export Location**: Saved to app documents, not user-accessible folder on some devices
7. **No Image Upload**: Candidate/user photos not yet implemented
8. ~~**Session Overlap**: No validation to prevent double-booking~~ **FIXED** ✅

---

## Recent Improvements (November 2024)

### ✅ Session Overlap Validation - IMPLEMENTED
- DatabaseService now checks for overlapping sessions before creation/update
- Prevents double-booking for the same candidate
- Clear error messages when conflicts detected
- Can be disabled if needed with `checkOverlap: false` parameter

### ✅ 15-Minute Time Intervals - IMPLEMENTED
- Calendar now displays 15-minute time slots (8:00, 8:15, 8:30, etc.)
- Custom time picker supports 15-minute intervals
- Sessions can start at any quarter hour
- Better accommodation for varied schedules

### ✅ Overlapping Session Display - IMPLEMENTED
- Multiple candidates' sessions at the same time display side-by-side
- Automatic cell width adjustment for overlaps
- Clear visual separation between concurrent sessions

### ✅ Developer Tools - IMPLEMENTED
- Comprehensive testing and database management screen
- Generate realistic test data for development
- Safe cleanup operations (users protected)
- Real-time statistics dashboard

---

## Performance Considerations

### Firestore Query Optimization
- Use `.limit()` on large collections
- Create indexes for frequently queried fields
- Use `.where()` filters before `.orderBy()`

### State Management
- StreamBuilder for real-time updates
- FutureBuilder for one-time data fetches
- Minimize rebuilds with `const` constructors

### Asset Optimization
- Compress images in `assets/images/`
- Use SVG for icons when possible
- Lazy load images with `Image.network()`

---

## Dependencies Summary

### Production Dependencies
```yaml
firebase_core: ^4.2.1          # Firebase initialization
cloud_firestore: ^6.1.0        # Database
firebase_auth: ^6.1.2          # Authentication
shared_preferences: ^2.5.3     # Local storage
image_picker: ^1.2.0           # Photo selection
http: ^1.5.0                   # HTTP requests
permission_handler: ^12.0.1    # Permissions
fluttertoast: ^9.0.0           # Toast notifications
image: ^4.5.4                  # Image processing
intl: ^0.20.2                  # Internationalization
flutter_localization: ^0.3.3   # Localization
url_launcher: ^6.3.1           # External URLs/apps
path_provider: ^2.1.4          # File system paths
```

### Dev Dependencies
```yaml
flutter_test: SDK              # Testing framework
flutter_lints: ^5.0.0          # Linting rules
```

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── bottom_navbar.dart                 # Main navigation
├── firebase_options.dart              # Firebase config (gitignored)
├── controllers/
│   ├── auth_wrapper.dart              # Auth state management
│   ├── user_controller.dart           # User state
│   └── app_preferences.dart           # Shared preferences
├── models/
│   ├── structs.dart                   # Model exports
│   ├── user_model.dart                # User model
│   ├── candidate_model.dart           # Candidate model
│   └── session_model.dart             # Session model
├── screens/
│   ├── dashboard_screen.dart          # Main dashboard
│   ├── calendar_screen.dart           # Weekly calendar
│   ├── candidates_list_screen.dart    # Candidates list
│   ├── candidate_detail_screen.dart   # Candidate details
│   ├── add_session_screen.dart        # Add/edit session
│   ├── profile_screen.dart            # User profile (legacy)
│   ├── settings_screens/
│   │   ├── settings_page.dart         # Settings main
│   │   ├── edit_profile.dart          # Edit profile
│   │   └── contact_support.dart       # Support form
│   └── user_management/
│       └── login.dart                 # Login screen
├── services/
│   └── export_service.dart            # CSV export
├── widgets/
│   ├── candidate_card.dart            # Candidate list item
│   ├── session_tile.dart              # Session list item
│   ├── loading_screen.dart            # Loading indicator
│   ├── snack_bar.dart                 # Custom snackbar
│   └── widgets.dart                   # Widget exports
├── l10n/
│   ├── app_localizations.dart         # Localization class
│   ├── app_en.arb                     # English
│   ├── app_fr.arb                     # French
│   └── app_ar.arb                     # Arabic
└── helpers/
    ├── image_compress.dart            # Image compression
    └── image_upload.dart              # Image upload to Firebase
```

---

## Deployment Checklist

### Before Release
- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Verify Firebase project is in production mode
- [ ] Set up Firestore security rules
- [ ] Create required Firestore indexes
- [ ] Configure app signing (Android)
- [ ] Configure provisioning profiles (iOS)
- [ ] Update app icons and splash screens
- [ ] Set proper app name in all platform folders
- [ ] Test deep links (if any)
- [ ] Review and update privacy policy
- [ ] Test payment tracking thoroughly
- [ ] Verify CSV export works on target devices
- [ ] Check app permissions in manifest files

### Version 1.0.0 Ready
- All core features implemented
- All critical bugs fixed
- Tested in production environment
- Documentation complete
- User manual created (if needed)

---

## Support & Maintenance

### Monitoring
- Set up Firebase Crashlytics
- Monitor Firestore usage and costs
- Track Auth success/failure rates
- Review user feedback regularly

### Updates
- Flutter SDK updates: Check quarterly
- Firebase SDK updates: Check monthly
- Dependency updates: Review weekly
- Security patches: Apply immediately

---

## Contact & Resources

**Developer**: [Your Name/Team]
**Version**: 1.0.0
**Last Updated**: November 5, 2024

**Useful Links**:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)
- [Dart Language](https://dart.dev/)

---

*This documentation reflects the current implementation status as of the specified date. For the most up-to-date information, refer to the codebase and git commit history.*
