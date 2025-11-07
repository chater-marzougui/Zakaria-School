import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @addCandidate.
  ///
  /// In en, this message translates to:
  /// **'Add Candidate'**
  String get addCandidate;

  /// No description provided for @addSession.
  ///
  /// In en, this message translates to:
  /// **'Add Session'**
  String get addSession;

  /// No description provided for @addSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Session'**
  String get addSessionTitle;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get anUnexpectedErrorOccurred;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @applyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get applyChanges;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @assignedInstructor.
  ///
  /// In en, this message translates to:
  /// **'Assigned Instructor'**
  String get assignedInstructor;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @candidate.
  ///
  /// In en, this message translates to:
  /// **'Candidate'**
  String get candidate;

  /// No description provided for @candidateName.
  ///
  /// In en, this message translates to:
  /// **'Candidate Name'**
  String get candidateName;

  /// No description provided for @candidatePhone.
  ///
  /// In en, this message translates to:
  /// **'Candidate Phone'**
  String get candidatePhone;

  /// No description provided for @candidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidates;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @chooseAnImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose an image source'**
  String get chooseAnImageSource;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @currentSelectedThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Current: {_selectedThemeMode}'**
  String currentSelectedThemeMode(Object _selectedThemeMode);

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataExported;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSession;

  /// No description provided for @deleteSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session?'**
  String get deleteSessionMessage;

  /// No description provided for @developerInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get developerInfo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @editInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editInfo;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editSession.
  ///
  /// In en, this message translates to:
  /// **'Edit Session'**
  String get editSession;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @enterTheSubjectOfYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the subject of your message'**
  String get enterTheSubjectOfYourMessage;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourEmailToRecoverYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to recover your password'**
  String get enterYourEmailToRecoverYourPassword;

  /// No description provided for @enterYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterYourMessage;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @errorOccurredWhileUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while uploading the image: {e}'**
  String errorOccurredWhileUploadingImage(Object e);

  /// No description provided for @errorReauthenticatingUser.
  ///
  /// In en, this message translates to:
  /// **'Error reauthenticating user: {e}'**
  String errorReauthenticatingUser(Object e);

  /// No description provided for @errorSendingPasswordRecoveryEmail.
  ///
  /// In en, this message translates to:
  /// **'Error sending password recovery email: {e}'**
  String errorSendingPasswordRecoveryEmail(Object e);

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out'**
  String get errorSigningOut;

  /// No description provided for @errorSubmittingSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'Error submitting support request'**
  String get errorSubmittingSupportRequest;

  /// No description provided for @errorUpdatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error updating password: {e}'**
  String errorUpdatingPassword(Object e);

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {e}'**
  String errorUpdatingProfile(Object e);

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @hiThereImBBot.
  ///
  /// In en, this message translates to:
  /// **'👋 Hi there! I\'m B-BOT'**
  String get hiThereImBBot;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmailAddress;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @loginFailedWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {message}'**
  String loginFailedWithMessage(Object message);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @markPayment.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment'**
  String get markPayment;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @nextSession.
  ///
  /// In en, this message translates to:
  /// **'Next Session'**
  String get nextSession;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAccountFoundWithThisEmail.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get noAccountFoundWithThisEmail;

  /// No description provided for @noCandidatesYet.
  ///
  /// In en, this message translates to:
  /// **'No candidates yet'**
  String get noCandidatesYet;

  /// No description provided for @noSessionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No sessions this week'**
  String get noSessionsThisWeek;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long and contain a number'**
  String get passwordRequirements;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal Account'**
  String get personalAccount;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @pleaseEnterLabel.
  ///
  /// In en, this message translates to:
  /// **'Please enter {label}'**
  String pleaseEnterLabel(Object label);

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @recoverPassword.
  ///
  /// In en, this message translates to:
  /// **'Recover Password'**
  String get recoverPassword;

  /// No description provided for @remainingHours.
  ///
  /// In en, this message translates to:
  /// **'Remaining Hours'**
  String get remainingHours;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduled;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @searchCandidates.
  ///
  /// In en, this message translates to:
  /// **'Search candidates...'**
  String get searchCandidates;

  /// No description provided for @selectCandidate.
  ///
  /// In en, this message translates to:
  /// **'Select Candidate'**
  String get selectCandidate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectInstructor.
  ///
  /// In en, this message translates to:
  /// **'Select Instructor'**
  String get selectInstructor;

  /// No description provided for @sendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp'**
  String get sendWhatsApp;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @sessionNote.
  ///
  /// In en, this message translates to:
  /// **'Session Note'**
  String get sessionNote;

  /// No description provided for @sessionStatus.
  ///
  /// In en, this message translates to:
  /// **'Session Status'**
  String get sessionStatus;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInToContinueYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get signInToContinueYourJourney;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @supcomAddress.
  ///
  /// In en, this message translates to:
  /// **'Sup\'Com Raoued Km 3,5 - 2083, Ariana Tunisie'**
  String get supcomAddress;

  /// No description provided for @supportRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted successfully'**
  String get supportRequestSubmittedSuccessfully;

  /// No description provided for @tapAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Tap again to exit'**
  String get tapAgainToExit;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @theoryPassed.
  ///
  /// In en, this message translates to:
  /// **'Theory Passed'**
  String get theoryPassed;

  /// No description provided for @thisAccountHasBeenDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled'**
  String get thisAccountHasBeenDisabled;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @todaySessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sessions'**
  String get todaySessions;

  /// No description provided for @tooManyFailedAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later'**
  String get tooManyFailedAttempts;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get totalHours;

  /// No description provided for @totalPaidHours.
  ///
  /// In en, this message translates to:
  /// **'Total Paid Hours'**
  String get totalPaidHours;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @totalTakenHours.
  ///
  /// In en, this message translates to:
  /// **'Total Taken Hours'**
  String get totalTakenHours;

  /// No description provided for @typeYourOldPasswordAndTheNewOneToApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Type your old password and the new one to apply changes'**
  String get typeYourOldPasswordAndTheNewOneToApplyChanges;

  /// No description provided for @typeYourPasswordToApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Type your password to apply changes'**
  String get typeYourPasswordToApplyChanges;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @unpaidSummary.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Summary'**
  String get unpaidSummary;

  /// No description provided for @upcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Sessions'**
  String get upcomingSessions;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @wouldYouLikeToTakeAPictureOrChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Would you like to take a picture or choose from gallery?'**
  String get wouldYouLikeToTakeAPictureOrChooseFromGallery;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @youCanInteractWithMeInMultipleWays.
  ///
  /// In en, this message translates to:
  /// **'You can interact with me in multiple ways:'**
  String get youCanInteractWithMeInMultipleWays;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @cin.
  ///
  /// In en, this message translates to:
  /// **'CIN'**
  String get cin;

  /// No description provided for @candidateCin.
  ///
  /// In en, this message translates to:
  /// **'Candidate CIN'**
  String get candidateCin;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @weeklyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Weekly Availability'**
  String get weeklyAvailability;

  /// No description provided for @noAvailabilitySet.
  ///
  /// In en, this message translates to:
  /// **'No availability set yet'**
  String get noAvailabilitySet;

  /// No description provided for @addAvailability.
  ///
  /// In en, this message translates to:
  /// **'Add Availability'**
  String get addAvailability;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @deleteTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Delete Time Slot'**
  String get deleteTimeSlot;

  /// No description provided for @availabilitySchedule.
  ///
  /// In en, this message translates to:
  /// **'Availability Schedule'**
  String get availabilitySchedule;

  /// No description provided for @editCandidate.
  ///
  /// In en, this message translates to:
  /// **'Edit Candidate'**
  String get editCandidate;

  /// No description provided for @updateCandidate.
  ///
  /// In en, this message translates to:
  /// **'Update Candidate'**
  String get updateCandidate;

  /// No description provided for @deleteCandidate.
  ///
  /// In en, this message translates to:
  /// **'Delete Candidate'**
  String get deleteCandidate;

  /// No description provided for @deleteCandidateMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this candidate? This will also delete all their sessions.'**
  String get deleteCandidateMessage;

  /// No description provided for @candidateCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Candidate created successfully'**
  String get candidateCreatedSuccessfully;

  /// No description provided for @candidateUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Candidate updated successfully'**
  String get candidateUpdatedSuccessfully;

  /// No description provided for @candidateDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Candidate deleted successfully'**
  String get candidateDeletedSuccessfully;

  /// No description provided for @failedToCreateCandidate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create candidate'**
  String get failedToCreateCandidate;

  /// No description provided for @failedToUpdateCandidate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update candidate'**
  String get failedToUpdateCandidate;

  /// No description provided for @failedToDeleteCandidate.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete candidate'**
  String get failedToDeleteCandidate;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @graduated.
  ///
  /// In en, this message translates to:
  /// **'Graduated'**
  String get graduated;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get selectStatus;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number is invalid'**
  String get phoneNumberInvalid;

  /// No description provided for @cinInvalid.
  ///
  /// In en, this message translates to:
  /// **'CIN must be 8 digits'**
  String get cinInvalid;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @sortByStartDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Start Date'**
  String get sortByStartDate;

  /// No description provided for @sortByProgress.
  ///
  /// In en, this message translates to:
  /// **'Sort by Progress'**
  String get sortByProgress;

  /// No description provided for @sortByRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'Sort by Remaining Hours'**
  String get sortByRemainingHours;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @showingResults.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} candidates'**
  String showingResults(Object count, Object total);

  /// No description provided for @totalCandidates.
  ///
  /// In en, this message translates to:
  /// **'Total Candidates'**
  String get totalCandidates;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @cinExample.
  ///
  /// In en, this message translates to:
  /// **'12345678'**
  String get cinExample;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'🛠️ Developer Tools'**
  String get developerTools;

  /// No description provided for @customTestData.
  ///
  /// In en, this message translates to:
  /// **'Custom Test Data'**
  String get customTestData;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete ALL candidates and sessions? This action cannot be undone!'**
  String get deleteAllDataConfirmation;

  /// No description provided for @allDataDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All candidates and sessions deleted successfully'**
  String get allDataDeletedSuccessfully;

  /// No description provided for @failedToDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete data: {error}'**
  String failedToDeleteData(Object error);

  /// No description provided for @generateTestData.
  ///
  /// In en, this message translates to:
  /// **'Generate Test Data'**
  String get generateTestData;

  /// No description provided for @generateTestDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will create fake candidates and sessions for testing. Continue?'**
  String get generateTestDataConfirmation;

  /// No description provided for @testDataGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Test data generated successfully'**
  String get testDataGeneratedSuccessfully;

  /// No description provided for @failedToGenerateTestData.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate test data: {error}'**
  String failedToGenerateTestData(Object error);

  /// No description provided for @createdCandidatesAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Created {candidateCount} candidates and {sessionCount} sessions'**
  String createdCandidatesAndSessions(Object candidateCount, Object sessionCount);

  /// No description provided for @failedToGenerateCustomData.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate custom data: {error}'**
  String failedToGenerateCustomData(Object error);

  /// No description provided for @failedToLoadStatistics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics: {error}'**
  String failedToLoadStatistics(Object error);

  /// No description provided for @refreshStatistics.
  ///
  /// In en, this message translates to:
  /// **'Refresh Statistics'**
  String get refreshStatistics;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @createTestDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Create 21 candidates and 180 sessions'**
  String get createTestDataDescription;

  /// No description provided for @specifyNumberOfCandidatesAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Specify number of candidates and sessions'**
  String get specifyNumberOfCandidatesAndSessions;

  /// No description provided for @removeAllCandidatesAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Remove all candidates and sessions'**
  String get removeAllCandidatesAndSessions;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @numberOfCandidates.
  ///
  /// In en, this message translates to:
  /// **'Number of Candidates'**
  String get numberOfCandidates;

  /// No description provided for @numberOfSessions.
  ///
  /// In en, this message translates to:
  /// **'Number of Sessions'**
  String get numberOfSessions;

  /// No description provided for @maximumCandidatesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} candidates allowed'**
  String maximumCandidatesAllowed(Object max);

  /// No description provided for @maximumSessionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} sessions allowed'**
  String maximumSessionsAllowed(Object max);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current: {language}'**
  String currentLanguage(Object language);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @exportCandidatesAndSessionsToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export candidates and sessions to CSV'**
  String get exportCandidatesAndSessionsToCSV;

  /// No description provided for @testingAndDatabaseManagement.
  ///
  /// In en, this message translates to:
  /// **'Testing and database management'**
  String get testingAndDatabaseManagement;

  /// No description provided for @developedForDrivingSchoolManagement.
  ///
  /// In en, this message translates to:
  /// **'Developed for driving school management'**
  String get developedForDrivingSchoolManagement;

  /// No description provided for @copyrightAllRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2024 All rights reserved'**
  String get copyrightAllRightsReserved;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @fifteenMinuteIntervals.
  ///
  /// In en, this message translates to:
  /// **'15-minute intervals'**
  String get fifteenMinuteIntervals;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @failedToCreateCandidate2.
  ///
  /// In en, this message translates to:
  /// **'Failed to create candidate: {error}'**
  String failedToCreateCandidate2(Object error);

  /// No description provided for @failedToGetCandidate.
  ///
  /// In en, this message translates to:
  /// **'Failed to get candidate: {error}'**
  String failedToGetCandidate(Object error);

  /// No description provided for @failedToGetCandidates.
  ///
  /// In en, this message translates to:
  /// **'Failed to get candidates: {error}'**
  String failedToGetCandidates(Object error);

  /// No description provided for @failedToUpdateCandidate2.
  ///
  /// In en, this message translates to:
  /// **'Failed to update candidate: {error}'**
  String failedToUpdateCandidate2(Object error);

  /// No description provided for @failedToDeleteCandidate2.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete candidate: {error}'**
  String failedToDeleteCandidate2(Object error);

  /// No description provided for @failedToDeleteAllCandidates.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all candidates: {error}'**
  String failedToDeleteAllCandidates(Object error);

  /// No description provided for @sessionOverlapError.
  ///
  /// In en, this message translates to:
  /// **'This candidate already has a session at this time. Sessions cannot overlap for the same candidate.'**
  String get sessionOverlapError;

  /// No description provided for @failedToCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to create session: {error}'**
  String failedToCreateSession(Object error);

  /// No description provided for @failedToGetSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to get session: {error}'**
  String failedToGetSession(Object error);

  /// No description provided for @failedToGetSessions.
  ///
  /// In en, this message translates to:
  /// **'Failed to get sessions: {error}'**
  String failedToGetSessions(Object error);

  /// No description provided for @failedToGetSessionsInDateRange.
  ///
  /// In en, this message translates to:
  /// **'Failed to get sessions in date range: {error}'**
  String failedToGetSessionsInDateRange(Object error);

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get sessionNotFound;

  /// No description provided for @failedToUpdateSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to update session: {error}'**
  String failedToUpdateSession(Object error);

  /// No description provided for @failedToDeleteSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete session: {error}'**
  String failedToDeleteSession(Object error);

  /// No description provided for @failedToDeleteAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all sessions: {error}'**
  String failedToDeleteAllSessions(Object error);

  /// No description provided for @failedToCheckSessionOverlap.
  ///
  /// In en, this message translates to:
  /// **'Failed to check session overlap: {error}'**
  String failedToCheckSessionOverlap(Object error);

  /// No description provided for @failedToGetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Failed to get statistics: {error}'**
  String failedToGetStatistics(Object error);

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to:\n{candidatesPath}\n{sessionsPath}'**
  String exportedTo(Object candidatesPath, Object sessionsPath);

  /// No description provided for @failedToSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save file: {error}'**
  String failedToSaveFile(Object error);

  /// No description provided for @developerToolsWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning: These tools are for testing only. Use with caution!'**
  String get developerToolsWarning;

  /// No description provided for @databaseStatistics.
  ///
  /// In en, this message translates to:
  /// **'📊 Database Statistics'**
  String get databaseStatistics;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'⚡ Quick Actions'**
  String get quickActions;

  /// No description provided for @initializingApp.
  ///
  /// In en, this message translates to:
  /// **'Initializing app...'**
  String get initializingApp;

  /// No description provided for @loadingCandidates.
  ///
  /// In en, this message translates to:
  /// **'Loading candidates...'**
  String get loadingCandidates;

  /// No description provided for @loadingSessions.
  ///
  /// In en, this message translates to:
  /// **'Loading sessions...'**
  String get loadingSessions;

  /// No description provided for @settingUpInitialData.
  ///
  /// In en, this message translates to:
  /// **'Setting up initial data...'**
  String get settingUpInitialData;

  /// No description provided for @errorInitializingApp.
  ///
  /// In en, this message translates to:
  /// **'Error initializing app'**
  String get errorInitializingApp;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save them before leaving?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSaved;

  /// No description provided for @availabilityInstructions.
  ///
  /// In en, this message translates to:
  /// **'Long press and drag to create availability slots'**
  String get availabilityInstructions;

  /// No description provided for @noSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get noSessionsFound;

  /// No description provided for @paymentMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as paid'**
  String get paymentMarkedAsPaid;

  /// No description provided for @paymentMarkedAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as unpaid'**
  String get paymentMarkedAsUnpaid;

  /// No description provided for @confirmPaymentStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the payment status?'**
  String get confirmPaymentStatusChange;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'👥 User Management'**
  String get userManagement;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @instructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructor;

  /// No description provided for @secretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get secretary;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully. You will be signed out and need to sign in again.'**
  String get userCreatedSuccessfully;

  /// No description provided for @failedToCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user: {error}'**
  String failedToCreateUser(Object error);

  /// No description provided for @userUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdatedSuccessfully;

  /// No description provided for @failedToUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user: {error}'**
  String failedToUpdateUser(Object error);

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user? This action cannot be undone.'**
  String get deleteUserConfirmation;

  /// No description provided for @userDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeletedSuccessfully;

  /// No description provided for @failedToDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user: {error}'**
  String failedToDeleteUser(Object error);

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users: {error}'**
  String failedToLoadUsers(Object error);

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// No description provided for @instructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get instructors;

  /// No description provided for @secretaries.
  ///
  /// In en, this message translates to:
  /// **'Secretaries'**
  String get secretaries;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @developerAccessOnly.
  ///
  /// In en, this message translates to:
  /// **'This screen is only accessible to users with developer role.'**
  String get developerAccessOnly;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
