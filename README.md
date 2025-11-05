Framework: Flutter
Backend: Firebase (Firestore + Auth + optional Storage)
Purpose: Driving school (auto-école) management app with scheduling, candidate tracking, and payments.
Users: 2–4 (theory teacher + instructor) no RBAC all users have same access

- No registration flow, users are pre-registered in Firestore by admin.
- Simple login with email and password.
- Dashboard with overview of upcoming sessions, pending payments, and recent activities.
- Calendar view for scheduling and managing driving sessions.
- Candidate management with detailed profiles, session history, and payment tracking.
- Session scheduling with status updates (scheduled, done, missed, rescheduled).
- Payment tracking for each candidate, including total paid hours, total taken hours.
- Export data to CSV for reporting purposes
- Settings screen for app preferences (e.g., notification settings, theme).
- Responsive design for mobile and tablet devices.
- Basic error handling and user feedback (e.g., snack bars, loading indicators).
- Integration with Firebase Firestore for real-time data synchronization.
- Localization support for multiple languages (English, French, Arabic).
- Dark mode support.
- Offline support with data caching.
- No in-app purchases, payments or ads.
- No third-party integrations beyond Firebase services.
- No complex analytics or user behavior tracking.
- Send messages via SMS to candidates (using device's default SMS app).
- Send messages via WhatsApp to candidates (using device's default WhatsApp app).

📂 Folder Structure
```
lib/
  main.dart
  firebase_options.dart
  bottom_navbar.dart
  controllers/
    auth_wrapper.dart
    user_controller.dart
    app_preferences.dart
  screens/
    dashboard_screen.dart
    calendar_screen.dart
    candidates_list_screen.dart
    candidate_detail_screen.dart
    add_session_screen.dart
    settings_screen.dart
  models/
    structs.dart
    user_model.dart
    candidate_model.dart
  services/
    export_service.dart
  widgets/
    candidate_card.dart
    session_tile.dart
    loading_screen.dart
    snack_bar.dart
    widgets.dart
```

🧠 Firestore Collections
```
/users
  uid -> { name, email, phone }

/candidates
  candidate_id -> {
    name,
    phone,
    start_date,
    theory_passed,
    total_paid_hours,
    total_taken_hours,
    balance,
    notes,
    assigned_instructor,
    status
  }

/sessions
  session_id -> {
    candidate_id,
    instructor_id,
    date,
    start_time,
    end_time,
    status, // scheduled | done | missed | rescheduled
    note,
    payment_status // paid | unpaid
  }
```

## 🏠 Dashboard Screen

Data shown:
- Today’s confirmed sessions (sessions where date == today && status == "scheduled" or "done"`)
- Upcoming 5 sessions (sorted by time)
- Quick unpaid summary (sum of unpaid sessions)
- Optional “Add Session” floating button

## 📅 Calendar Screen

Weekly view (7 days × hours)
Pull sessions for the selected week from /sessions

Colored blocks:
- 🟢 Confirmed
- 🔵 Done
- 🟠 Rescheduled
- 🔴 Missed

Tap → see details / edit session

## 👤 Candidate Detail Screen

Tabs or sections:
- Info: name, phone, start date 
- Schedule: upcoming + past sessions 
- Payments: list with status 
- Notes: free text field, editable

Include:
- “Add Session” button
- “Mark Payment” button
- “Edit Info” button

## 📇 Candidates List Screen
Search bar (by name or phone)
List view → each item shows:
- Name and prename
- Progress bar (% hours done)
- Payment status
- Next session time
- Tap → Candidate Detail Screen
- FAB: Add New Candidate (form → adds to /candidates)

## 💰 Add Session Screen
Form Fields:
- Candidate dropdown 
- Instructor dropdown 
- Date picker 
- Start/End time pickers 
- Status selector 
- Payment status 
- Notes field 
- Submit → creates or updates a /sessions doc.

## ⚙️ Settings Screen (got an initial working setup - needs adjustments)
Options:
- Theme selection (light/dark/system)
- Language selection (English, French, Arabic)
- Export data (triggers CSV export)
- About section (app version, developer info)
