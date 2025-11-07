// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get about => 'حول';

  @override
  String get addCandidate => 'إضافة مرشح';

  @override
  String get addSession => 'إضافة جلسة';

  @override
  String get addSessionTitle => 'إضافة جلسة';

  @override
  String get anUnexpectedErrorOccurred => 'حدث خطأ غير متوقع';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get applyChanges => 'تطبيق التغييرات';

  @override
  String get areYouSureYouWantToLogout => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get assignedInstructor => 'المدرب المعين';

  @override
  String get calendar => 'التقويم';

  @override
  String get camera => 'الكاميرا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get candidate => 'المرشح';

  @override
  String get candidateName => 'اسم المرشح';

  @override
  String get candidatePhone => 'هاتف المرشح';

  @override
  String get candidates => 'المرشحون';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get chooseAnImageSource => 'اختر مصدر الصورة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get contactSupport => 'الاتصال بالدعم';

  @override
  String currentSelectedThemeMode(Object _selectedThemeMode) {
    return 'الحالي: $_selectedThemeMode';
  }

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get dataExported => 'تم تصدير البيانات بنجاح';

  @override
  String get date => 'التاريخ';

  @override
  String get deleteSession => 'حذف الجلسة';

  @override
  String get deleteSessionMessage => 'هل أنت متأكد من حذف هذه الجلسة؟';

  @override
  String get developerInfo => 'معلومات المطور';

  @override
  String get done => 'منجز';

  @override
  String get editInfo => 'تعديل المعلومات';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editSession => 'تعديل الجلسة';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get endTime => 'وقت الانتهاء';

  @override
  String get enterTheSubjectOfYourMessage => 'أدخل موضوع رسالتك';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourEmailToRecoverYourPassword => 'أدخل بريدك الإلكتروني لاستعادة كلمة المرور';

  @override
  String get enterYourMessage => 'أدخل رسالتك';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String errorOccurredWhileUploadingImage(Object e) {
    return 'حدث خطأ أثناء رفع الصورة: $e';
  }

  @override
  String errorReauthenticatingUser(Object e) {
    return 'خطأ أثناء إعادة التحقق من المستخدم: $e';
  }

  @override
  String errorSendingPasswordRecoveryEmail(Object e) {
    return 'خطأ أثناء إرسال بريد استعادة كلمة المرور: $e';
  }

  @override
  String get errorSigningOut => 'خطأ أثناء تسجيل الخروج';

  @override
  String get errorSubmittingSupportRequest => 'خطأ أثناء إرسال طلب الدعم';

  @override
  String errorUpdatingPassword(Object e) {
    return 'خطأ أثناء تحديث كلمة المرور: $e';
  }

  @override
  String errorUpdatingProfile(Object e) {
    return 'خطأ أثناء تحديث الملف الشخصي: $e';
  }

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get exportFailed => 'فشل التصدير';

  @override
  String get failedToUploadImage => 'فشل في رفع الصورة';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get gallery => 'المعرض';

  @override
  String get hiThereImBBot => '👋 أهلاً! أنا B-BOT';

  @override
  String get hour => 'ساعة';

  @override
  String get hours => 'ساعات';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get info => 'معلومات';

  @override
  String get invalidEmailAddress => 'عنوان البريد الإلكتروني غير صالح';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get location => 'الموقع';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String loginFailedWithMessage(Object message) {
    return 'فشل تسجيل الدخول: $message';
  }

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get markPayment => 'وضع علامة الدفع';

  @override
  String get missed => 'فائت';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get nextSession => 'الجلسة القادمة';

  @override
  String get no => 'لا';

  @override
  String get noAccountFoundWithThisEmail => 'لا يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get noCandidatesYet => 'لا يوجد مرشحون بعد';

  @override
  String get noSessionsThisWeek => 'لا توجد جلسات هذا الأسبوع';

  @override
  String get noSessionsYet => 'لا توجد جلسات بعد';

  @override
  String get notes => 'ملاحظات';

  @override
  String get oldPassword => 'كلمة المرور القديمة';

  @override
  String get orContinueWith => 'أو المتابعة عبر';

  @override
  String get paid => 'مدفوع';

  @override
  String get passwordRequirements => 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل وتحتوي على رقم';

  @override
  String get passwordUpdatedSuccessfully => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get paymentStatus => 'حالة الدفع';

  @override
  String get payments => 'المدفوعات';

  @override
  String get personalAccount => 'حساب شخصي';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get pleaseEnterAValidEmailAddress => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String pleaseEnterLabel(Object label) {
    return 'يرجى إدخال $label';
  }

  @override
  String get pleaseFillInAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get recoverPassword => 'استعادة كلمة المرور';

  @override
  String get remainingHours => 'الساعات المتبقية';

  @override
  String get rescheduled => 'معاد جدولته';

  @override
  String get save => 'حفظ';

  @override
  String get schedule => 'الجدول';

  @override
  String get scheduled => 'مجدول';

  @override
  String get searchCandidates => 'بحث عن المرشحين...';

  @override
  String get selectCandidate => 'اختر المرشح';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get selectInstructor => 'اختر المدرب';

  @override
  String get sendWhatsApp => 'إرسال واتساب';

  @override
  String get sessionDetails => 'تفاصيل الجلسة';

  @override
  String get sessionNote => 'ملاحظة الجلسة';

  @override
  String get sessionStatus => 'حالة الجلسة';

  @override
  String get sessions => 'الجلسات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInToContinueYourJourney => 'سجل الدخول لمتابعة رحلتك';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get startTime => 'وقت البدء';

  @override
  String get status => 'الحالة';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get supcomAddress => 'المدرسة العليا للمواصلات - رواد كم 3.5، 2083، أريانة، تونس';

  @override
  String get supportRequestSubmittedSuccessfully => 'تم إرسال طلب الدعم بنجاح';

  @override
  String get tapAgainToExit => 'اضغط مرة أخرى للخروج';

  @override
  String get themeMode => 'وضع السمة';

  @override
  String get theoryPassed => 'اجتاز النظري';

  @override
  String get thisAccountHasBeenDisabled => 'تم تعطيل هذا الحساب';

  @override
  String get time => 'الوقت';

  @override
  String get todaySessions => 'جلسات اليوم';

  @override
  String get tooManyFailedAttempts => 'عدد كبير جدًا من المحاولات الفاشلة. يرجى المحاولة لاحقًا';

  @override
  String get totalHours => 'الساعات الإجمالية';

  @override
  String get totalPaidHours => 'الساعات المدفوعة';

  @override
  String get totalSessions => 'إجمالي الجلسات';

  @override
  String get totalTakenHours => 'الساعات المنجزة';

  @override
  String get typeYourOldPasswordAndTheNewOneToApplyChanges => 'اكتب كلمة المرور القديمة والجديدة لتطبيق التغييرات';

  @override
  String get typeYourPasswordToApplyChanges => 'اكتب كلمة المرور لتطبيق التغييرات';

  @override
  String get unpaid => 'غير مدفوع';

  @override
  String get unpaidSummary => 'ملخص غير المدفوع';

  @override
  String get upcomingSessions => 'الجلسات القادمة';

  @override
  String get voice => 'صوت';

  @override
  String get welcomeBack => 'مرحبًا بعودتك!';

  @override
  String get wouldYouLikeToTakeAPictureOrChooseFromGallery => 'هل ترغب في التقاط صورة أو الاختيار من المعرض؟';

  @override
  String get wrongPassword => 'كلمة مرور خاطئة';

  @override
  String get yes => 'نعم';

  @override
  String get youCanInteractWithMeInMultipleWays => 'يمكنك التفاعل معي بعدة طرق:';

  @override
  String get edit => 'تعديل';

  @override
  String get duration => 'المدة';

  @override
  String get cin => 'رقم بطاقة التعريف';

  @override
  String get candidateCin => 'رقم بطاقة تعريف المرشح';

  @override
  String get availability => 'التوفر';

  @override
  String get weeklyAvailability => 'التوفر الأسبوعي';

  @override
  String get noAvailabilitySet => 'لم يتم تحديد التوفر بعد';

  @override
  String get addAvailability => 'إضافة التوفر';

  @override
  String get monday => 'الإثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get deleteTimeSlot => 'حذف الفترة الزمنية';

  @override
  String get availabilitySchedule => 'جدول التوفر';

  @override
  String get editCandidate => 'تعديل المرشح';

  @override
  String get updateCandidate => 'تحديث المرشح';

  @override
  String get deleteCandidate => 'حذف المرشح';

  @override
  String get deleteCandidateMessage => 'هل أنت متأكد من حذف هذا المرشح؟ سيؤدي هذا أيضًا إلى حذف جميع جلساته.';

  @override
  String get candidateCreatedSuccessfully => 'تم إنشاء المرشح بنجاح';

  @override
  String get candidateUpdatedSuccessfully => 'تم تحديث المرشح بنجاح';

  @override
  String get candidateDeletedSuccessfully => 'تم حذف المرشح بنجاح';

  @override
  String get failedToCreateCandidate => 'فشل إنشاء المرشح';

  @override
  String get failedToUpdateCandidate => 'فشل تحديث المرشح';

  @override
  String get failedToDeleteCandidate => 'فشل حذف المرشح';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get graduated => 'متخرج';

  @override
  String get selectStatus => 'اختر الحالة';

  @override
  String get phoneNumberInvalid => 'رقم الهاتف غير صالح';

  @override
  String get cinInvalid => 'يجب أن يتكون رقم البطاقة من 8 أرقام';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortByName => 'ترتيب حسب الاسم';

  @override
  String get sortByStartDate => 'ترتيب حسب تاريخ البدء';

  @override
  String get sortByProgress => 'ترتيب حسب التقدم';

  @override
  String get sortByRemainingHours => 'ترتيب حسب الساعات المتبقية';

  @override
  String get ascending => 'تصاعدي';

  @override
  String get descending => 'تنازلي';

  @override
  String showingResults(Object count, Object total) {
    return 'عرض $count من $total المرشحين';
  }

  @override
  String get totalCandidates => 'إجمالي المرشحين';

  @override
  String get optional => 'اختياري';

  @override
  String get none => 'لا شيء';

  @override
  String get cinExample => '12345678';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get developerTools => '🛠️ أدوات المطور';

  @override
  String get customTestData => 'بيانات اختبار مخصصة';

  @override
  String get generate => 'إنشاء';

  @override
  String get deleteAllData => 'حذف جميع البيانات';

  @override
  String get deleteAllDataConfirmation => 'هل أنت متأكد من رغبتك في حذف جميع المرشحين والجلسات؟ لا يمكن التراجع عن هذا الإجراء!';

  @override
  String get allDataDeletedSuccessfully => 'تم حذف جميع المرشحين والجلسات بنجاح';

  @override
  String failedToDeleteData(Object error) {
    return 'فشل حذف البيانات: $error';
  }

  @override
  String get generateTestData => 'إنشاء بيانات اختبار';

  @override
  String get generateTestDataConfirmation => 'سيؤدي هذا إلى إنشاء مرشحين وجلسات وهمية للاختبار. هل تريد المتابعة؟';

  @override
  String get testDataGeneratedSuccessfully => 'تم إنشاء بيانات الاختبار بنجاح';

  @override
  String failedToGenerateTestData(Object error) {
    return 'فشل إنشاء بيانات الاختبار: $error';
  }

  @override
  String createdCandidatesAndSessions(Object candidateCount, Object sessionCount) {
    return 'تم إنشاء $candidateCount مرشحًا و $sessionCount جلسة';
  }

  @override
  String failedToGenerateCustomData(Object error) {
    return 'فشل إنشاء البيانات المخصصة: $error';
  }

  @override
  String failedToLoadStatistics(Object error) {
    return 'فشل تحميل الإحصائيات: $error';
  }

  @override
  String get refreshStatistics => 'تحديث الإحصائيات';

  @override
  String get total => 'المجموع';

  @override
  String get createTestDataDescription => 'إنشاء 21 مرشحًا و 180 جلسة';

  @override
  String get specifyNumberOfCandidatesAndSessions => 'تحديد عدد المرشحين والجلسات';

  @override
  String get removeAllCandidatesAndSessions => 'إزالة جميع المرشحين والجلسات';

  @override
  String get information => 'معلومات';

  @override
  String get numberOfCandidates => 'عدد المرشحين';

  @override
  String get numberOfSessions => 'عدد الجلسات';

  @override
  String maximumCandidatesAllowed(Object max) {
    return 'الحد الأقصى $max مرشحًا مسموحًا';
  }

  @override
  String maximumSessionsAllowed(Object max) {
    return 'الحد الأقصى $max جلسة مسموحة';
  }

  @override
  String get language => 'اللغة';

  @override
  String currentLanguage(Object language) {
    return 'الحالية: $language';
  }

  @override
  String get english => 'الإنجليزية';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get exportCandidatesAndSessionsToCSV => 'تصدير المرشحين والجلسات إلى CSV';

  @override
  String get testingAndDatabaseManagement => 'الاختبار وإدارة قاعدة البيانات';

  @override
  String get developedForDrivingSchoolManagement => 'تم التطوير بواسطة شاطر مرزوقي';

  @override
  String get copyrightAllRightsReserved => '© 2025 جميع الحقوق محفوظة';

  @override
  String get minute => 'دقيقة';

  @override
  String get ok => 'حسناً';

  @override
  String get fifteenMinuteIntervals => 'فواصل زمنية مدتها 15 دقيقة';

  @override
  String error(Object error) {
    return 'خطأ: $error';
  }

  @override
  String failedToCreateCandidate2(Object error) {
    return 'فشل إنشاء المرشح: $error';
  }

  @override
  String failedToGetCandidate(Object error) {
    return 'فشل الحصول على المرشح: $error';
  }

  @override
  String failedToGetCandidates(Object error) {
    return 'فشل الحصول على المرشحين: $error';
  }

  @override
  String failedToUpdateCandidate2(Object error) {
    return 'فشل تحديث المرشح: $error';
  }

  @override
  String failedToDeleteCandidate2(Object error) {
    return 'فشل حذف المرشح: $error';
  }

  @override
  String failedToDeleteAllCandidates(Object error) {
    return 'فشل حذف جميع المرشحين: $error';
  }

  @override
  String get sessionOverlapError => 'هذا المرشح لديه جلسة بالفعل في هذا الوقت. لا يمكن أن تتداخل الجلسات لنفس المرشح.';

  @override
  String failedToCreateSession(Object error) {
    return 'فشل إنشاء الجلسة: $error';
  }

  @override
  String failedToGetSession(Object error) {
    return 'فشل الحصول على الجلسة: $error';
  }

  @override
  String failedToGetSessions(Object error) {
    return 'فشل الحصول على الجلسات: $error';
  }

  @override
  String failedToGetSessionsInDateRange(Object error) {
    return 'فشل الحصول على الجلسات في نطاق التاريخ: $error';
  }

  @override
  String get sessionNotFound => 'لم يتم العثور على الجلسة';

  @override
  String failedToUpdateSession(Object error) {
    return 'فشل تحديث الجلسة: $error';
  }

  @override
  String failedToDeleteSession(Object error) {
    return 'فشل حذف الجلسة: $error';
  }

  @override
  String failedToDeleteAllSessions(Object error) {
    return 'فشل حذف جميع الجلسات: $error';
  }

  @override
  String failedToCheckSessionOverlap(Object error) {
    return 'فشل التحقق من تداخل الجلسات: $error';
  }

  @override
  String failedToGetStatistics(Object error) {
    return 'فشل الحصول على الإحصائيات: $error';
  }

  @override
  String exportedTo(Object candidatesPath, Object sessionsPath) {
    return 'تم التصدير إلى:\n$candidatesPath\n$sessionsPath';
  }

  @override
  String failedToSaveFile(Object error) {
    return 'فشل حفظ الملف: $error';
  }

  @override
  String get developerToolsWarning => '⚠️ تحذير: هذه الأدوات للاختبار فقط. استخدمها بحذر!';

  @override
  String get databaseStatistics => '📊 إحصائيات قاعدة البيانات';

  @override
  String get quickActions => '⚡ إجراءات سريعة';

  @override
  String get initializingApp => 'جاري تهيئة التطبيق...';

  @override
  String get loadingCandidates => 'جاري تحميل المرشحين...';

  @override
  String get loadingSessions => 'جاري تحميل الجلسات...';

  @override
  String get settingUpInitialData => 'جاري إعداد البيانات الأولية...';

  @override
  String get errorInitializingApp => 'خطأ في تهيئة التطبيق';

  @override
  String get retry => 'إعادة محاولة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage => 'لديك تغييرات غير محفوظة. هل تريد حفظها قبل المغادرة؟';

  @override
  String get discard => 'تجاهل';

  @override
  String get changesSaved => 'تم حفظ التغييرات بنجاح';

  @override
  String get availabilityInstructions => 'اضغط لفترة طويلة واسحب لإنشاء فترات توفر';

  @override
  String get noSessionsFound => 'لم يتم العثور على جلسات';

  @override
  String get paymentMarkedAsPaid => 'تم تحديد الدفع كمدفوع';

  @override
  String get paymentMarkedAsUnpaid => 'تم تحديد الدفع كغير مدفوع';

  @override
  String get confirmPaymentStatusChange => 'هل أنت متأكد من أنك تريد تغيير حالة الدفع؟';

  @override
  String get markAsPaid => 'تحديد كمدفوع';

  @override
  String get markAsUnpaid => 'تحديد كغير مدفوع';

  @override
  String get userManagement => '👥 إدارة المستخدمين';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get editUser => 'تعديل المستخدم';

  @override
  String get firstNameRequired => 'الاسم الأول مطلوب';

  @override
  String get lastNameRequired => 'اسم العائلة مطلوب';

  @override
  String get phoneNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get selectRole => 'اختر الدور';

  @override
  String get instructor => 'مدرب';

  @override
  String get secretary => 'سكرتير';

  @override
  String get developer => 'مطور';

  @override
  String get userCreatedSuccessfully => 'تم إنشاء المستخدم بنجاح. سيتم تسجيل خروجك وستحتاج إلى تسجيل الدخول مرة أخرى.';

  @override
  String failedToCreateUser(Object error) {
    return 'فشل في إنشاء المستخدم: $error';
  }

  @override
  String get userUpdatedSuccessfully => 'تم تحديث المستخدم بنجاح';

  @override
  String failedToUpdateUser(Object error) {
    return 'فشل في تحديث المستخدم: $error';
  }

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get deleteUserConfirmation => 'هل أنت متأكد من أنك تريد حذف هذا المستخدم؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get userDeletedSuccessfully => 'تم حذف المستخدم بنجاح';

  @override
  String failedToDeleteUser(Object error) {
    return 'فشل في حذف المستخدم: $error';
  }

  @override
  String failedToLoadUsers(Object error) {
    return 'فشل في تحميل المستخدمين: $error';
  }

  @override
  String get noUsers => 'لم يتم العثور على مستخدمين';

  @override
  String get instructors => 'المدربون';

  @override
  String get secretaries => 'السكرتيرات';

  @override
  String get allUsers => 'جميع المستخدمين';

  @override
  String get passwordMinLength => 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';

  @override
  String get invalidEmail => 'عنوان البريد الإلكتروني غير صالح';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get developerAccessOnly => 'هذه الشاشة متاحة فقط للمستخدمين ذوي دور المطور.';

  @override
  String get planningSessions => 'جاري التخطيط للجلسات...';

  @override
  String get creatingSessions => 'جاري إنشاء الجلسات...';

  @override
  String get success => 'نجح!';

  @override
  String get planningFailed => 'فشل التخطيط';

  @override
  String successfullyCreatedSessions(Object count) {
    return 'تم إنشاء $count جلسة بنجاح';
  }

  @override
  String totalHoursScheduled(Object hours) {
    return 'إجمالي الساعات المجدولة: $hours ساعة';
  }

  @override
  String get confirmAndCreate => 'تأكيد وإنشاء';

  @override
  String get autoSessionPlanning => 'التخطيط التلقائي للجلسات';

  @override
  String howManyHoursToSchedule(Object name) {
    return 'كم عدد الساعات التي تريد جدولتها لـ $name؟';
  }

  @override
  String get hoursToSchedule => 'الساعات المراد جدولتها';

  @override
  String get exampleHours => 'مثلاً، 10';

  @override
  String get systemWillFitSessions => 'سيحاول النظام ملاءمة الجلسات في جدول المدرب بناءً على توفر المرشح.';

  @override
  String get planSessions => 'تخطيط الجلسات';

  @override
  String get pleaseEnterValidHours => 'الرجاء إدخال عدد ساعات صحيح';

  @override
  String get paymentAmount => 'مبلغ الدفع';

  @override
  String get paymentDate => 'تاريخ الدفع';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get examplePaymentNote => 'مثلاً، عربون، دفعة كاملة، إلخ.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get sendScheduleToInstructor => 'إرسال الجدول إلى المدرب';
}
