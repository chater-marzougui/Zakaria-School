# Localization Update Instructions

## Changes Made

This PR adds localization for previously hardcoded strings in the application. The following files have been updated:

### Localization Files (ARB)
- `lib/l10n/app_en.arb` - Added 61 new localization keys
- `lib/l10n/app_fr.arb` - Added French translations for all new keys
- `lib/l10n/app_ar.arb` - Added Arabic translations for all new keys

### Updated Code Files
- `lib/screens/settings_screens/developer_screen.dart` - All hardcoded strings now use localized versions
- `lib/screens/settings_screens/settings_page.dart` - Language selector and other strings localized
- `lib/screens/add_session_screen.dart` - Time picker and error messages localized
- `lib/screens/calendar_screen.dart` - Error messages localized
- `lib/screens/candidate_detail_screen.dart` - Error messages localized
- `lib/screens/candidates_list_screen.dart` - Error messages localized
- `lib/screens/dashboard_screen.dart` - Error messages localized
- `lib/services/export_service.dart` - Export messages now return structured data for localization at UI level

## Important: Regenerate Localization Files

The auto-generated Dart localization files need to be regenerated to include the new keys. 

**Run this command before building or running the app:**

```bash
flutter gen-l10n
```

Or simply build/run the app, which will automatically trigger the generation:

```bash
flutter run
# or
flutter build apk
```

The following files will be automatically regenerated:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_fr.dart`
- `lib/l10n/app_localizations_ar.dart`

## What Was NOT Localized

The following items were intentionally not localized:

1. **Collection Names**: Firestore collection names (e.g., 'candidates', 'sessions')
2. **Database Keys**: Field names in Firestore documents
3. **CSV Headers**: Export file headers remain in English for consistency
4. **Enum Values**: Status values like 'active', 'paid', 'scheduled' (used as data values)
5. **Technical Error Details**: The actual error messages from exceptions (wrapped in localized error format)

## Testing

After regenerating the localization files, test the following:

1. Change app language in Settings and verify all UI text updates correctly
2. Try generating test data in Developer Tools
3. Try deleting data in Developer Tools
4. Create/edit sessions and verify time picker labels
5. Export data and verify success message shows correctly
6. Trigger session overlap error and verify localized message appears

## Validation

All .arb files have been validated for correct JSON syntax.
