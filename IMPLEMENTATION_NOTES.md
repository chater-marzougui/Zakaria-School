# Implementation Notes: CIN and Availability Schedule

## Summary
This implementation adds two major features to the Zakaria School driving school management app:

1. **CIN (Carte d'Identité Nationale) field for candidates** - A national ID card number
2. **Weekly availability schedule for candidates** - Allows tracking when candidates are available for lessons

## Changes Made

### 1. Data Model Changes (`lib/models/candidate_model.dart`)

#### Added TimeSlot class
- New data structure to represent time slots with `startTime` and `endTime`
- Includes serialization methods (`toMap` and `fromMap`) for Firestore storage

#### Updated Candidate class
- Added `cin` field (String, defaults to empty string)
- Added `availability` field (Map<String, List<TimeSlot>>) to store weekly schedule
- Updated `fromFirestore()` to deserialize availability data from Firestore
- Updated `toFirestore()` to serialize availability data to Firestore

### 2. Localization Updates

Added new translation keys to all three language files (English, French, Arabic):
- `cin` - CIN label
- `candidateCin` - Candidate CIN field label
- `availability` - Availability label
- `weeklyAvailability` - Weekly availability title
- `noAvailabilitySet` - Message when no availability is set
- `addAvailability` - Add availability button
- `monday` through `sunday` - Day names
- `from` - From time label
- `to` - To time label
- `deleteTimeSlot` - Delete time slot action
- `availabilitySchedule` - Availability schedule description

### 3. UI Changes

#### `lib/screens/candidates_list_screen.dart`
- Updated search functionality to include CIN in search queries (line 88-91)
- Added CIN input field to the "Add Candidate" dialog
- Made dialog scrollable to accommodate the new field
- Updated candidate creation to include CIN value

#### `lib/screens/candidate_detail_screen.dart`
- Changed TabController from 3 tabs to 4 tabs
- Added new "Availability" tab between "Info" and "Schedule"
- Added CIN display in the Info tab (with credit_card icon)
- Implemented `_buildAvailabilityTab()` method:
  - Displays weekly availability schedule organized by day
  - Shows all time slots for each day of the week
  - Provides add/delete functionality for time slots
  - Uses StreamBuilder to react to real-time Firestore updates
  
- Implemented `_addTimeSlot()` method:
  - Opens dialog to select start and end times
  - Uses Flutter's TimePicker widget
  - Updates Firestore with new time slot
  
- Implemented `_deleteTimeSlot()` method:
  - Shows confirmation dialog
  - Removes time slot from Firestore
  - Cleans up empty days from availability map

### 4. Test Data Generator (`lib/helpers/seed_db.dart`)
- Updated `_generateCandidate()` to include random 8-digit CIN numbers
- Ensures test data matches the new data model

## Usage

### Adding a Candidate with CIN
1. Navigate to Candidates screen
2. Tap the "Add Candidate" button
3. Fill in Name, Phone, and CIN (CIN is optional)
4. Tap Save

### Searching by CIN
1. Go to Candidates screen
2. Type CIN number in the search bar
3. Candidates matching the CIN will appear in results

### Managing Availability Schedule
1. Open a candidate's detail screen
2. Tap on the "Availability" tab (second tab)
3. For each day of the week:
   - Tap the "+" button to add a time slot
   - Select start and end times using the time picker
   - Tap Save
4. To delete a time slot:
   - Tap the delete icon next to the time slot
   - Confirm deletion

### Viewing Availability
The availability schedule is organized by day of the week (Monday through Sunday). Each day shows:
- List of time slots when the candidate is available
- Time displayed in 24-hour format (HH:MM - HH:MM)
- Visual indicators (clock icon and colored background)

## Technical Details

### Data Storage Structure in Firestore

```javascript
// Candidate document
{
  name: "John Doe",
  phone: "+216 12 345 678",
  cin: "12345678",
  availability: {
    monday: [
      { start_time: "09:00", end_time: "12:00" },
      { start_time: "14:00", end_time: "17:00" }
    ],
    wednesday: [
      { start_time: "10:00", end_time: "16:00" }
    ]
    // ... other days
  }
  // ... other fields
}
```

### Backwards Compatibility
- CIN field defaults to empty string for existing candidates
- Availability defaults to empty map for existing candidates
- No migration required - existing data will work with new code

## Future Enhancements

Potential improvements that could be made:
1. Add validation for CIN format (e.g., must be 8 digits)
2. Add conflict detection when scheduling sessions (check availability)
3. Add bulk availability setting (e.g., "same time every weekday")
4. Add availability export/import functionality
5. Add notifications when trying to schedule outside availability
6. Add visual calendar view of availability
7. Integrate availability checking in session creation workflow

## Testing Recommendations

1. **CIN Field Testing:**
   - Add new candidate with CIN
   - Add candidate without CIN (should work fine)
   - Search by CIN number
   - Edit existing candidate to add CIN
   - Verify CIN displays in candidate info

2. **Availability Testing:**
   - Add availability for different days
   - Add multiple time slots per day
   - Delete time slots
   - View availability on different screen sizes
   - Test with existing candidates (should show empty availability)
   - Test real-time updates (open same candidate in two places)

3. **Backwards Compatibility:**
   - Existing candidates should load without errors
   - Search should work with candidates that don't have CIN
   - Availability tab should show "No availability set" for old candidates
