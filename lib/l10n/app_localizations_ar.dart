// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'هيفي رِنت';

  @override
  String get tooltipLogin => 'تسجيل الدخول';

  @override
  String get tooltipLogout => 'تسجيل الخروج';

  @override
  String get admin => 'مسؤول';

  @override
  String get signedIn => 'تم تسجيل الدخول';

  @override
  String get signedOut => 'تم تسجيل الخروج';

  @override
  String get heroTitle => 'معدات ثقيلة، عمل أسهل';

  @override
  String get heroSubtitle => 'استأجر آلات مع سائقين عند الطلب.';

  @override
  String get findEquipment => 'ابحث عن معدات';

  @override
  String get popularEquipment => 'المعدات الشائعة';

  @override
  String get seeMore => 'المزيد';

  @override
  String get couldNotLoadEquipment => 'تعذر تحميل المعدات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noEquipmentYet => 'لا توجد معدات بعد.';

  @override
  String get rent => 'استئجار';

  @override
  String fromPerDay(String price) {
    return 'ابتداءً من $price / يوم';
  }

  @override
  String distanceKm(String km) {
    return '$km كم';
  }

  @override
  String get langEnglish => 'الإنجليزية';

  @override
  String get langArabic => 'العربية';

  @override
  String get appTitle => 'هيفي رِنت';

  @override
  String get actionSignIn => 'تسجيل الدخول';

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String get actionRentNow => 'استئجار الآن';

  @override
  String get actionApply => 'تطبيق';

  @override
  String get actionFilter => 'تصفية';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get searchHint => 'ابحث عن المعدات أو العلامات أو المدن...';

  @override
  String get phone => 'الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get otp => 'رمز التحقق';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get verifyCode => 'تحقق';

  @override
  String get withDriver => 'مع سائق';

  @override
  String pricePerDay(String price) {
    return '$price / يوم';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: 'نتيجة واحدة',
      zero: 'لا توجد نتائج',
    );
    return '$_temp0';
  }

  @override
  String validationRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String get validationEmail => 'الرجاء إدخال بريد إلكتروني صالح';

  @override
  String msgOtpSent(String phone) {
    return 'تم إرسال الرمز إلى $phone';
  }

  @override
  String get snackSaved => 'تم الحفظ';

  @override
  String get snackError => 'حدث خطأ ما';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get homeHeadline => 'معدات ثقيلة، عمل أسهل';

  @override
  String get homeSub => 'استأجر معدات معتمدة عند الطلب';

  @override
  String get discoverTitle => 'اكتشف';

  @override
  String get filters => 'عوامل التصفية';

  @override
  String get filterBrand => 'العلامة التجارية';

  @override
  String get filterCity => 'المدينة';

  @override
  String get filterPriceDay => 'السعر/اليوم';

  @override
  String get filterHasCerts => 'شهادات سارية';

  @override
  String get filterDistance => 'سعر المسافة';

  @override
  String get filterApply => 'تطبيق التصفية';

  @override
  String get filterReset => 'إعادة ضبط';

  @override
  String get emptyTitle => 'لا توجد نتائج';

  @override
  String get emptyBody => 'جرّب تعديل التصفية أو كلمات البحث';

  @override
  String get appSettings => 'إعدادات التطبيق';

  @override
  String get selectTime => 'اختر الوقت';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get test => 'تجربة';

  @override
  String get testNotificationMessage => 'هذه رسالة إشعار تجريبية';

  @override
  String get pushNotifications => 'إشعارات الدفع';

  @override
  String get inAppBanners => 'تنبيهات داخل التطبيق';

  @override
  String get emailUpdates => 'تحديثات البريد الإلكتروني';

  @override
  String get sound => 'الصوت';

  @override
  String get quietHours => 'ساعات الهدوء';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get quietHoursHint => 'خلال ساعات الهدوء يتم كتم الأصوات. (تجريبي — اربطه بمزوّد الإشعارات لاحقًا)';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get notAvailableTitle => 'غير متاح';

  @override
  String get signInRequiredTitle => 'يلزم تسجيل الدخول';

  @override
  String get restrictedPageMessage => 'هذه الصفحة متاحة فقط للحسابات ذات نوع المستخدم ‎#17 أو ‎#20.';

  @override
  String get signInPrompt => 'يرجى تسجيل الدخول للمتابعة.';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusIncomplete => 'غير مكتمل';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmBody => 'يمكنك تسجيل الدخول مرة أخرى في أي وقت.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get completeYourAccountBody => 'أكمل حسابك للوصول إلى المؤسسة ومعداتي.';

  @override
  String get completeAction => 'إكمال';

  @override
  String get accountSection => 'الحساب';

  @override
  String get manageSection => 'إدارة';

  @override
  String get activitySection => 'النشاط';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSubtitle => 'بياناتك الشخصية وبيانات الشركة';

  @override
  String get appSettingsSubtitle => 'السمة، اللغة، الإشعارات';

  @override
  String get organizationTitle => 'المؤسسة';

  @override
  String get organizationSubtitle => 'معلومات الشركة والامتثال';

  @override
  String get myEquipmentTitle => 'معداتي';

  @override
  String get myEquipmentSubtitle => 'عرض وإدارة أسطولك';

  @override
  String get requestsTitle => 'الطلبات';

  @override
  String get requestsSubtitle => 'إدارة طلباتك';

  @override
  String get superAdminTitle => 'مشرف النظام';

  @override
  String get superAdminSubtitle => 'فتح لوحة مشرف النظام (تصحيح)';

  @override
  String get contractsTitle => 'العقود';

  @override
  String get contractsSubtitle => 'قيد الانتظار، مفتوحة، منتهية، مغلقة';

  @override
  String get ordersHistoryTitle => 'الطلبات (سجل)';

  @override
  String get ordersHistorySubtitle => 'الطلبات السابقة والإيصالات';

  @override
  String get mobileNumber => 'رقم الجوال';

  @override
  String get codeLabel => 'الرمز';

  @override
  String get codeHint => '966';

  @override
  String get mobile9DigitsLabel => 'الجوال (9 أرقام)';

  @override
  String get mobile9DigitsHint => '5XX XXX XXX';

  @override
  String get enterNineDigits => 'أدخل 9 أرقام';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String devOtpHint(String code) {
    return 'رمز المطور: $code';
  }

  @override
  String get enterCodeTitle => 'أدخل الرمز';

  @override
  String get verifyAndContinue => 'تحقق وتابع';

  @override
  String get didntGetItTapResend => 'لم يصلك؟ اضغط \"إعادة إرسال الرمز\".';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signInWithMobileBlurb => 'سجّل الدخول برقم جوالك.\nطريقة سريعة وآمنة عبر رمز التحقق.';

  @override
  String get neverShareNumber => 'لن نشارك رقمك مع أي جهة.';

  @override
  String get otpSent => 'تم إرسال الرمز';

  @override
  String get couldNotStartVerification => 'تعذّر بدء عملية التحقق';

  @override
  String get enterFourDigitCode => 'أدخل رمزًا مكوّنًا من 4 أرقام';

  @override
  String get invalidOrExpiredCode => 'رمز غير صحيح أو منتهي الصلاحية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get passwordKeep => 'كلمة المرور';

  @override
  String validationMinChars(int min) {
    return 'الحد الأدنى $min أحرف';
  }

  @override
  String get actionSaveChanges => 'حفظ التغييرات';

  @override
  String get actionReset => 'إعادة التعيين';

  @override
  String get profileCompletePrompt => 'أكمل ملفك الشخصي';

  @override
  String get failedToLoadProfile => 'فشل تحميل الملف الشخصي';

  @override
  String get couldNotSaveProfile => 'تعذّر حفظ الملف الشخصي';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get orgTitle => 'المنشأة';

  @override
  String get orgCreateTitle => 'إنشاء منشأة';

  @override
  String get orgType => 'النوع';

  @override
  String get orgStatus => 'الحالة';

  @override
  String get orgNameArabic => 'الاسم (العربية)';

  @override
  String get orgNameEnglish => 'الاسم (الإنجليزية)';

  @override
  String get orgBriefArabic => 'نبذة (العربية)';

  @override
  String get orgBriefEnglish => 'نبذة (الإنجليزية)';

  @override
  String get orgCountry => 'الدولة';

  @override
  String get orgCity => 'المدينة';

  @override
  String get orgAddress => 'العنوان';

  @override
  String get orgCrNumber => 'رقم السجل التجاري';

  @override
  String get orgVatNumber => 'الرقم الضريبي';

  @override
  String get orgMainMobile => 'الجوال الأساسي';

  @override
  String get orgSecondMobile => 'الجوال الثاني';

  @override
  String get orgMainEmail => 'البريد الإلكتروني الأساسي';

  @override
  String get orgSecondEmail => 'البريد الإلكتروني الثاني';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get actionSave => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get orgFilesTitle => 'الملفات • المرفقات';

  @override
  String get orgAddFile => 'إضافة ملف';

  @override
  String get orgCreateToManageFiles => 'أنشئ منشأة لإدارة الملفات.';

  @override
  String get orgNoFilesYet => 'لا توجد ملفات بعد.';

  @override
  String get attachmentTitle => 'مرفق';

  @override
  String get fileType => 'نوع الملف';

  @override
  String get addFileNameRequired => 'أدخل اسم الملف *';

  @override
  String get pickFile => 'اختيار ملف *';

  @override
  String get descriptionOptional => 'وصف (اختياري)';

  @override
  String get issueDate => 'تاريخ الإصدار';

  @override
  String get expireDate => 'تاريخ الانتهاء';

  @override
  String get image => 'صورة';

  @override
  String get active => 'نشط';

  @override
  String get expired => 'منتهي';

  @override
  String get orgEnterNameMin3 => 'يرجى إدخال اسم (3 أحرف فأكثر)';

  @override
  String get orgChooseTypeStatusCity => 'يرجى اختيار الحالة والنوع والمدينة';

  @override
  String get createFailed => 'فشل الإنشاء';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get orgCreated => 'تم إنشاء المنشأة';

  @override
  String get orgUpdated => 'تم تحديث المنشأة';

  @override
  String get orgCouldNotSave => 'تعذّر حفظ المنشأة';

  @override
  String get failedToLoadOrganization => 'فشل تحميل بيانات المنشأة';

  @override
  String get orgCreateFirst => 'أنشئ منشأة أولاً';

  @override
  String get chooseFileType => 'اختر نوع الملف';

  @override
  String get pickFileNameRequired => 'اختر ملفًا — الاسم مطلوب';

  @override
  String get fileAdded => 'تمت إضافة الملف';

  @override
  String get fileUpdated => 'تم تحديث الملف';

  @override
  String get couldNotSaveFile => 'تعذّر حفظ الملف';

  @override
  String get deleteFileTitle => 'حذف الملف';

  @override
  String get deleteFileBody => 'هل أنت متأكد من حذف هذا الملف؟';

  @override
  String get delete => 'حذف';

  @override
  String get deleteMissingId => 'تعذّر الحذف: رقم الملف مفقود';

  @override
  String get fileDeleted => 'تم حذف الملف';

  @override
  String get couldNotDeleteFile => 'تعذّر حذف الملف';

  @override
  String get myEquipSignInBody => 'يلزم تسجيل الدخول لإدارة معداتك.';

  @override
  String get orgNeededTitle => 'مطلوب منشأة';

  @override
  String get orgNeededBody => 'أضف منشأتك قبل إدراج أو إدارة المعدات.';

  @override
  String get actionAddOrganization => 'إضافة منشأة';

  @override
  String get submittedMayTakeMoment => 'تم الإرسال. قد يستغرق ظهوره لحظات.';

  @override
  String get cantAddEquipment => 'لا يمكن إضافة المعدة';

  @override
  String get actionOk => 'حسناً';

  @override
  String unexpectedErrorWithMsg(String msg) {
    return 'خطأ غير متوقع: $msg';
  }

  @override
  String get actionAddEquipment => 'إضافة معدة';

  @override
  String failedToLoadYourEquipment(String error) {
    return 'تعذّر تحميل معداتك.\n$error';
  }

  @override
  String get noEquipmentYetTapAdd => 'لا توجد معدات بعد. اضغط «إضافة معدة» للبدء.';

  @override
  String get openAsCustomerToRent => 'افتح كتاجر/عميل للاستئجار';

  @override
  String get signInRequired => 'يجب عليك تسجيل الدخول اولا';

  @override
  String get equipSettingsTitle => 'إعدادات المعدة';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabImages => 'الصور';

  @override
  String get tabTerms => 'الشروط';

  @override
  String get tabDrivers => 'السائقون';

  @override
  String get tabCertificates => 'الشهادات';

  @override
  String get basicInfo => 'معلومات أساسية';

  @override
  String get nameEn => 'الاسم (إنجليزي)';

  @override
  String get nameAr => 'الاسم (عربي)';

  @override
  String get exampleExcavator => 'مثال: Excavator 22T';

  @override
  String get exampleExcavatorAr => 'مثال: حفّار ٢٢ طن';

  @override
  String get pricing => 'التسعير';

  @override
  String get pricePerHour => 'السعر / ساعة';

  @override
  String downPaymentPct(Object pct, Object amount) {
    return 'الدفعة الأولى: $pct% → $amount';
  }

  @override
  String get quantityAndStatus => 'الكمية والحالة';

  @override
  String get quantity => 'الكمية';

  @override
  String get equipmentWeight => 'وزن المعدة';

  @override
  String get activeVisible => 'نشط (ظاهر)';

  @override
  String get inactiveHidden => 'غير نشط (مخفي)';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get noteSendsFullObject => 'ملاحظة: الحفظ يرسل كائناً كاملاً (معرّفات فقط) إلى PUT /Equipment/update.';

  @override
  String get saved => 'تم الحفظ';

  @override
  String saveFailedWithMsg(Object msg) {
    return 'فشل الحفظ: $msg';
  }

  @override
  String get uploading => 'جاري الرفع…';

  @override
  String get actionAddImage => 'إضافة صورة';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get noImagesYet => 'لا توجد صور بعد.';

  @override
  String get imageUploaded => 'تم رفع الصورة';

  @override
  String uploadFailedWithMsg(Object msg) {
    return 'فشل الرفع: $msg';
  }

  @override
  String get imageDeleted => 'تم حذف الصورة';

  @override
  String deleteFailedWithMsg(Object msg) {
    return 'فشل الحذف: $msg';
  }

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionAddTerm => 'إضافة شرط';

  @override
  String get actionSaveOrder => 'حفظ الترتيب';

  @override
  String get noTermsYetCreateFirst => 'لا توجد شروط بعد. اضغط «إضافة شرط» لإنشاء أول عنصر.';

  @override
  String get addTerm => 'إضافة شرط';

  @override
  String get editTerm => 'تعديل شرط';

  @override
  String get english => 'إنجليزي';

  @override
  String get arabic => 'عربي';

  @override
  String get order => 'الترتيب';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get deleted => 'تم الحذف';

  @override
  String get orderSaved => 'تم حفظ الترتيب';

  @override
  String orderSaveFailedWithMsg(Object msg) {
    return 'فشل حفظ الترتيب: $msg';
  }

  @override
  String get driver => 'سائق';

  @override
  String get nationalityIdLabel => 'معرّف الجنسية:';

  @override
  String get actionAddDriver => 'إضافة سائق';

  @override
  String get noDriversYet => 'لا يوجد سائقون بعد.';

  @override
  String get noFiles => 'لا توجد ملفات';

  @override
  String get fromDate => 'من';

  @override
  String get toDate => 'إلى';

  @override
  String get actionAddFile => 'إضافة ملف';

  @override
  String get deleteFileQ => 'حذف الملف؟';

  @override
  String get allFieldsRequired => 'جميع الحقول مطلوبة';

  @override
  String get fileAndTypeRequired => 'الملف ونوعه مطلوبان';

  @override
  String get actionAddCertificate => 'إضافة شهادة';

  @override
  String get noCertificatesYet => 'لا توجد شهادات بعد.';

  @override
  String get addCertificate => 'إضافة شهادة';

  @override
  String get editCertificate => 'تعديل شهادة';

  @override
  String get chooseFile => 'اختيار ملف';

  @override
  String get pdfSelected => 'تم اختيار PDF';

  @override
  String get nameEnReq => 'الاسم (إنجليزي) *';

  @override
  String get nameArReq => 'الاسم (عربي) *';

  @override
  String get typeDomain10Req => 'النوع*';

  @override
  String get issueDateReq => 'تاريخ الإصدار *';

  @override
  String get expireDateReq => 'تاريخ الانتهاء *';

  @override
  String get isImage => 'صورة؟';

  @override
  String get saving => 'جاري الحفظ…';

  @override
  String get pleasePickIssueAndExpire => 'يرجى اختيار تاريخ الإصدار والانتهاء.';

  @override
  String get pleaseChooseType => 'يرجى اختيار النوع.';

  @override
  String get pleaseChooseDocument => 'يرجى اختيار ملف الوثيقة.';

  @override
  String get deleteCertificateQ => 'حذف الشهادة؟';

  @override
  String get noPastOrdersYet => 'لا توجد طلبات سابقة بعد';

  @override
  String get failedToLoadOrders => 'فشل في تحميل الطلبات';

  @override
  String get myRequestsTitle => 'طلباتي';

  @override
  String get signInToViewRequests => 'سجّل الدخول لعرض طلباتك';

  @override
  String get signInToViewRequestsBody => 'يجب تسجيل الدخول لعرض سجل طلباتك وتفاصيلها.';

  @override
  String get failedToLoadRequests => 'فشل في تحميل الطلبات';

  @override
  String get noRequestsYet => 'لا توجد طلبات بعد.';

  @override
  String get requestNumber => 'طلب رقم #';

  @override
  String get asVendor => 'بصفة مزوّد';

  @override
  String get asCustomer => 'بصفة عميل';

  @override
  String get daysSuffix => 'يوم / أيام';

  @override
  String get requestDetailsTitle => 'تفاصيل الطلب';

  @override
  String get failedToLoadRequest => 'فشل في تحميل الطلب';

  @override
  String get sectionDuration => 'المدة';

  @override
  String get sectionPriceBreakdown => 'تفصيل الأسعار';

  @override
  String get priceBase => 'الأساسي';

  @override
  String get priceDistance => 'المسافة';

  @override
  String get priceVat => 'ضريبة القيمة المضافة';

  @override
  String get priceTotal => 'الإجمالي';

  @override
  String get priceDownPayment => 'الدفعة المقدمة';

  @override
  String get sectionAssignDrivers => 'تعيين السائقين';

  @override
  String get errorLoadDriverLocations => 'تعذر تحميل مواقع السائقين.';

  @override
  String get emptyNoDriverLocations => 'لا توجد مواقع سائقين لهذا الطلب.';

  @override
  String get errorNoDriversForNationality => 'بعض الوحدات لا تحتوي على سائقين متاحين للجنسية المطلوبة.';

  @override
  String get errorAssignDriverEachUnit => 'يرجى اختيار سائق لكل وحدة.';

  @override
  String get actionCreateContract => 'إنشاء عقد';

  @override
  String get creatingEllipsis => 'جارٍ الإنشاء…';

  @override
  String get actionCancelRequest => 'إلغاء الطلب';

  @override
  String get unitLabel => 'وحدة';

  @override
  String get requestedNationality => 'الجنسية المطلوبة';

  @override
  String get dropoffLabel => 'مكان التسليم';

  @override
  String get coordinatesLabel => 'الإحداثيات';

  @override
  String get emptyNoDriversForThisNationality => 'لا يوجد سائقون متاحون لهذه الجنسية.';

  @override
  String get labelAssignDriverFiltered => 'تعيين سائق (حسب الجنسية)';

  @override
  String get hintSelectDriver => 'اختر سائقًا';

  @override
  String get orderNumber => 'طلب رقم ';

  @override
  String get requestListLeadingLabel => 'طلب رقم ';

  @override
  String get currencySar => 'ر.س';

  @override
  String get pending => 'قيد الإصدار';

  @override
  String get daySingular => 'يوم';

  @override
  String get toDateSep => 'إلى';

  @override
  String get detailsCopied => 'تم نسخ التفاصيل';

  @override
  String get requestSubmittedTitle => 'تم إرسال الطلب';

  @override
  String get successTitle => 'تم بنجاح!';

  @override
  String get numberPendingChip => 'الرقم قيد الإصدار';

  @override
  String get requestSubmittedBody => 'تم إرسال طلبك بنجاح.';

  @override
  String get requestLabel => 'الطلب:';

  @override
  String get requestHashPrefix => 'رقم الطلب ';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get dateRangeLabel => 'نطاق التاريخ';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get actionCopyDetails => 'نسخ التفاصيل';

  @override
  String get actionDone => 'تم';

  @override
  String daysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# يوم',
      many: '# يومًا',
      few: '# أيام',
      two: '# يومان',
      one: '# يوم',
      zero: '# يوم',
    );
    return '$_temp0';
  }

  @override
  String get equipmentTitle => 'المعدات';

  @override
  String get searchByDescriptionHint => 'ابحث حسب الوصف…';

  @override
  String get failedToLoadEquipmentList => 'فشل تحميل قائمة المعدات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get equipEditorTitleNew => 'معدات جديدة';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get errorCouldNotLoadFactories => 'تعذّر تحميل المصانع';

  @override
  String get errorChooseEquipmentType => 'اختر نوع المعدّة';

  @override
  String get errorChooseFactory => 'اختر المصنع';

  @override
  String get errorEnterDescription => 'أدخل الوصف (إنجليزي أو عربي)';

  @override
  String get errorFailedToLoadOptions => 'فشل تحميل الخيارات';

  @override
  String get sectionType => 'النوع';

  @override
  String get labelEquipmentList => 'قائمة المعدات';

  @override
  String get selectedPrefix => 'المحدد:';

  @override
  String get sectionOwnershipStatus => 'الملكية والحالة';

  @override
  String get labelFactory => 'المصنع';

  @override
  String get hintSelectFactory => 'اختر مصنعاً';

  @override
  String get tooltipRefreshFactories => 'تحديث المصانع';

  @override
  String get labelStatusD11 => 'الحالة';

  @override
  String get sectionLogistics => 'الخدمات اللوجستية';

  @override
  String get labelCategoryD9 => 'الفئة';

  @override
  String get labelFuelRespD7 => 'مسؤولية الوقود';

  @override
  String get labelTransferTypeD8 => 'نوع النقل';

  @override
  String get labelTransferRespD7 => 'مسؤولية النقل';

  @override
  String get sectionDriverRespD7 => 'مسؤوليات السائق';

  @override
  String get labelTransport => 'النقل';

  @override
  String get labelFood => 'الطعام';

  @override
  String get labelHousing => 'السكن';

  @override
  String get sectionDescriptions => 'الأوصاف';

  @override
  String get labelDescEnglish => 'الوصف (بالإنجليزية)';

  @override
  String get hintDescEnglish => 'مثال: حفّار 22 طن';

  @override
  String get labelDescArabic => 'الوصف (بالعربية)';

  @override
  String get hintDescArabic => 'مثال: حفّار ٢٢ طن';

  @override
  String get sectionPricing => 'التسعير';

  @override
  String get labelPricePerDay => 'السعر لليوم';

  @override
  String get hintPricePerDay => 'مثال: 1600';

  @override
  String get labelPricePerHour => 'السعر للساعة';

  @override
  String get hintPricePerHour => 'مثال: 160';

  @override
  String ruleHoursPerDayAndDp(Object hours, Object percent) {
    return 'قاعدة: 1 يوم = $hours ساعة. الدفعة المقدمة = ‎$percent%‎.';
  }

  @override
  String downPaymentAuto(Object amount) {
    return 'الدفعة المقدمة (آلياً): $amount';
  }

  @override
  String get sectionQuantity => 'الكمية';

  @override
  String get labelQuantityAlsoAvailable => 'الكمية (وتُستخدم كالمتوفر)';

  @override
  String get hintQuantity => 'مثال: 1';

  @override
  String get noteAvailableReserved => 'المتوفر = الكمية، والمحجوز يبدأ من 0 (ويتم تحديثهما لاحقاً).';

  @override
  String get unnamedFactory => 'مصنع بدون اسم';

  @override
  String get contractTitle => 'العقد';

  @override
  String get actionOpenContractSheet => 'فتح سجل العقد';

  @override
  String get actionPrint => 'طباعة';

  @override
  String get printingStubMessage => 'تنبيه الطباعة — يرجى ربط الطباعة/‏PDF هنا.';

  @override
  String get errorFailedToLoadContractDetails => 'فشل تحميل تفاصيل العقد';

  @override
  String get errorNoContractSlice => 'لم يتم العثور على مقطع للعقد / لم يُنشأ.';

  @override
  String get rentalAgreementHeader => 'اتفاقية تأجير';

  @override
  String contractNumber(Object num) {
    return 'العقد رقم $num';
  }

  @override
  String get sectionParties => 'الأطراف';

  @override
  String get sectionRequestSummary => 'ملخص الطلب';

  @override
  String get sectionEquipment => 'المعدة';

  @override
  String get sectionResponsibilities => 'المسؤوليات (النطاق 7)';

  @override
  String get sectionTerms => 'الشروط';

  @override
  String get sectionDriverAssignments => 'تعيينات السائقين (لكل وحدة مطلوبة)';

  @override
  String get sectionSignatures => 'التواقيع';

  @override
  String get vendorLabel => 'المورّد';

  @override
  String get customerLabel => 'العميل';

  @override
  String get requestNumberLabel => 'رقم الطلب';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get daysLabel => 'الأيام';

  @override
  String get rentPerDayLabel => 'الإيجار / اليوم';

  @override
  String get subtotalLabel => 'الإجمالي الفرعي';

  @override
  String get vatLabel => 'ضريبة القيمة المضافة';

  @override
  String get downPaymentLabel => 'الدفعة المقدمة';

  @override
  String get titleLabel => 'العنوان';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get fuelResponsibilityLabel => 'مسؤولية الوقود';

  @override
  String get driverFoodLabel => 'طعام السائق';

  @override
  String get driverHousingLabel => 'سكن السائق';

  @override
  String get driverTransportLabel => 'نقل السائق';

  @override
  String responsibilityValue(Object label, Object id) {
    return '$label ';
  }

  @override
  String get termDownPayment => 'الدفعة المقدمة قبل التحريك؛ والباقي حسب الجدول المتفق عليه.';

  @override
  String get termManufacturerGuidelines => 'يجب استخدام المعدات وفقًا لإرشادات الشركة المصنّعة.';

  @override
  String get termCustomerSiteAccess => 'العميل مسؤول عن إتاحة الوصول للموقع وبيئة العمل الآمنة.';

  @override
  String get termLiability => 'الأضرار والمسؤولية حسب شروط الشركة والقوانين المعمول بها.';

  @override
  String get equipmentTermsHeading => 'شروط المعدة:';

  @override
  String get noDriverLocations => 'لا توجد مواقع سائقين لهذا الطلب.';

  @override
  String get requestedNationalityLabel => 'الجنسية المطلوبة';

  @override
  String get coordsLabel => 'الإحداثيات';

  @override
  String get assignedDriverLabel => 'السائق المعيّن';

  @override
  String get companyLogo => 'شعار الشركة';

  @override
  String detailHash(Object id) {
    return 'تفصيل رقم $id';
  }

  @override
  String get contractSheetTitle => 'سجل العقد';

  @override
  String contractChip(Object id) {
    return 'العقد رقم $id';
  }

  @override
  String requestChip(Object id) {
    return 'الطلب رقم $id';
  }

  @override
  String qtyChip(int qty) {
    return 'الكمية: $qty';
  }

  @override
  String dateRangeChip(Object from, Object to) {
    return '$from → $to';
  }

  @override
  String get roleVendor => 'الدور: المورّد';

  @override
  String get roleCustomer => 'الدور: العميل';

  @override
  String get rowNothingToSave => 'لا يوجد ما يتم حفظه في هذا الصف.';

  @override
  String rowLabel(Object unit, Object date) {
    return 'و$unit $date';
  }

  @override
  String rowSaved(Object label) {
    return 'تم الحفظ ($label).';
  }

  @override
  String rowSaveFailed(Object label) {
    return 'فشل الحفظ ($label).';
  }

  @override
  String get endpoint405Noop => 'واجهة التحديث غير مفعلة (405). لم يتم أي تغيير على الخادم.';

  @override
  String get savedChip => 'تم الحفظ';

  @override
  String get unsavedChip => 'غير محفوظ';

  @override
  String get plannedLabel => 'المخطط';

  @override
  String get actualLabel => 'الفعلي';

  @override
  String get overtimeLabel => 'الإضافي';

  @override
  String get customerNoteLabel => 'ملاحظة العميل';

  @override
  String get vendorNoteLabel => 'ملاحظة المورّد';

  @override
  String get savingEllipsis => 'جارٍ الحفظ…';

  @override
  String get infoCreateActivateOrg => 'يرجى إنشاء/تفعيل مؤسستك أولاً.';

  @override
  String get noContractsYet => 'لا توجد عقود حتى الآن.';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد.';

  @override
  String get chatsTitle => 'المحادثات';

  @override
  String get searchChats => 'ابحث في المحادثات';

  @override
  String get noChatsYet => 'لا توجد محادثات بعد.';

  @override
  String chatTitle(Object id) {
    return 'محادثة رقم $id';
  }

  @override
  String get threadActionsSoon => 'خيارات المحادثة قريباً';

  @override
  String get messageHint => 'اكتب رسالة';

  @override
  String get actionSend => 'إرسال';

  @override
  String get sendingEllipsis => 'جارٍ الإرسال…';

  @override
  String get timeNow => 'الآن';

  @override
  String timeMinutesShort(Object m) {
    return '$mد';
  }

  @override
  String timeHoursShort(Object h) {
    return '$hس';
  }

  @override
  String timeDaysShort(Object d) {
    return '$dي';
  }

  @override
  String get title_equipmentDetails => 'تفاصيل المعدّة';

  @override
  String get msg_failedLoadEquipment => 'فشل في تحميل بيانات المعدّة';

  @override
  String get label_availability => 'التوفر';

  @override
  String get label_rentFrom => 'تاريخ بدء الإيجار';

  @override
  String get hint_yyyyMMdd => 'YYYY-MM-DD';

  @override
  String get label_returnTo => 'تاريخ الإرجاع';

  @override
  String pill_days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: '$count يوم',
    );
    return '$_temp0';
  }

  @override
  String get label_expectedKm => 'المسافة المتوقعة (كم)';

  @override
  String mini_pricePerKm(Object currency, Object price) {
    return '$currency $price / كم';
  }

  @override
  String get label_quantity => 'الكمية';

  @override
  String get label_requestedQty => 'الكمية المطلوبة';

  @override
  String mini_available(Object count) {
    return 'المتوفر: $count';
  }

  @override
  String get label_driverLocations => 'مواقع السائقين';

  @override
  String get msg_loadingNats => 'جاري تحميل الجنسيات المتاحة للسائقين…';

  @override
  String get msg_noNats => 'لا توجد جنسيات سائقين متاحة لهذه المعدّة.';

  @override
  String get label_driverNationality => 'جنسية السائق *';

  @override
  String get label_dropoffAddress => 'عنوان التسليم';

  @override
  String get label_dropoffLat => 'إحداثي خط العرض *';

  @override
  String get label_dropoffLon => 'إحداثي خط الطول *';

  @override
  String get label_notes => 'ملاحظات';

  @override
  String chip_available(Object count) {
    return 'المتوفر: $count';
  }

  @override
  String get label_priceBreakdown => 'تفاصيل التسعير';

  @override
  String get row_perUnit => 'لكل وحدة';

  @override
  String row_base(Object days, Object price) {
    return 'الأساس ($price × $days يوم)';
  }

  @override
  String row_distance(Object km, Object pricePerKm) {
    return 'المسافة ($pricePerKm × $km كم)';
  }

  @override
  String row_vat(Object rate) {
    return 'ضريبة القيمة المضافة $rate٪';
  }

  @override
  String get row_perUnitTotal => 'إجمالي لكل وحدة';

  @override
  String row_qtyTimes(Object qty) {
    return '× الكمية ($qty)';
  }

  @override
  String get row_subtotal => 'الإجمالي الفرعي';

  @override
  String get row_vatOnly => 'الضريبة';

  @override
  String get row_total => 'الإجمالي';

  @override
  String get row_downPayment => 'الدفعة المقدمة';

  @override
  String get btn_submit => 'إرسال الطلب';

  @override
  String get btn_submitting => 'جاري الإرسال…';

  @override
  String row_fuel(Object value) {
    return 'الوقود: $value';
  }

  @override
  String get err_chooseDates => 'يرجى اختيار التواريخ';

  @override
  String get info_signInFirst => 'يرجى تسجيل الدخول أولاً';

  @override
  String get err_qtyMin => 'يجب أن تكون الكمية 1 على الأقل';

  @override
  String err_qtyAvail(Object count) {
    return 'متاح فقط $count قطعة';
  }

  @override
  String err_unitSelectNat(Object index) {
    return 'الوحدة $index: اختر الجنسية';
  }

  @override
  String err_unitLatLng(Object index) {
    return 'الوحدة $index: مطلوب إحداثيات التسليم';
  }

  @override
  String get err_vendorMissing => 'لا يوجد مورد لهذه المعدّة.';

  @override
  String get info_createOrg => 'يرجى إنشاء/تفعيل مؤسستك أولاً.';

  @override
  String get err_loadNats => 'تعذر تحميل جنسيات السائقين للمعدة.';

  @override
  String get err_loadResp => 'تعذر تحميل أسماء المسؤوليات.';

  @override
  String get equipDetailsTitle => 'تفاصيل المعدّة';

  @override
  String get msgFailedLoadEquipment => 'فشل في تحميل بيانات المعدّة';

  @override
  String get labelAvailability => 'التوفر';

  @override
  String get labelRentFrom => 'تاريخ بدء الإيجار';

  @override
  String get hintYyyyMmDd => 'YYYY-MM-DD';

  @override
  String get labelReturnTo => 'تاريخ الإرجاع';

  @override
  String pillDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: '$count يوم',
    );
    return '$_temp0';
  }

  @override
  String get labelExpectedKm => 'المسافة المتوقعة (كم)';

  @override
  String miniPricePerKm(String currency, String price) {
    return '$currency $price / كم';
  }

  @override
  String get labelQuantity => 'الكمية';

  @override
  String get labelRequestedQty => 'الكمية المطلوبة';

  @override
  String miniAvailable(int count) {
    return 'المتوفر: $count';
  }

  @override
  String get labelDriverLocations => 'مواقع السائقين';

  @override
  String get msgLoadingNats => 'جاري تحميل الجنسيات المتاحة للسائقين…';

  @override
  String get msgNoNats => 'لا توجد جنسيات سائقين متاحة لهذه المعدّة.';

  @override
  String get labelDriverNationality => 'جنسية السائق *';

  @override
  String get labelDropoffAddress => 'عنوان التسليم';

  @override
  String get labelDropoffLat => 'إحداثي خط العرض *';

  @override
  String get labelDropoffLon => 'إحداثي خط الطول *';

  @override
  String get labelNotes => 'ملاحظات';

  @override
  String get labelPriceBreakdown => 'تفاصيل التسعير';

  @override
  String get rowPerUnit => 'لكل وحدة';

  @override
  String rowBase(String price, String days) {
    return 'الأساس ($price × $days يوم)';
  }

  @override
  String rowDistance(String pricePerKm, String km) {
    return 'المسافة ($pricePerKm × $km كم)';
  }

  @override
  String rowVat(String rate) {
    return 'ضريبة القيمة المضافة $rate٪';
  }

  @override
  String get rowPerUnitTotal => 'إجمالي لكل وحدة';

  @override
  String rowQtyTimes(int qty) {
    return '× الكمية ($qty)';
  }

  @override
  String get rowSubtotal => 'الإجمالي الفرعي';

  @override
  String get rowVatOnly => 'الضريبة';

  @override
  String get rowTotal => 'الإجمالي';

  @override
  String get rowDownPayment => 'الدفعة المقدمة';

  @override
  String get btnSubmitting => 'جاري الإرسال…';

  @override
  String get btnSubmit => 'إرسال الطلب';

  @override
  String rowFuel(String value) {
    return 'الوقود: $value';
  }

  @override
  String get errChooseDates => 'يرجى اختيار التواريخ';

  @override
  String get infoSignInFirst => 'يرجى تسجيل الدخول أولاً';

  @override
  String get errQtyMin => 'يجب أن تكون الكمية 1 على الأقل';

  @override
  String errQtyAvail(int count) {
    return 'متاح فقط $count قطعة';
  }

  @override
  String errUnitSelectNat(int index) {
    return 'الوحدة $index: اختر الجنسية';
  }

  @override
  String errUnitLatLng(int index) {
    return 'الوحدة $index: مطلوب إحداثيات التسليم';
  }

  @override
  String get errVendorMissing => 'لا يوجد مورد لهذه المعدّة.';

  @override
  String get infoCreateOrgFirst => 'يرجى إنشاء/تفعيل مؤسستك أولاً.';

  @override
  String get errLoadNatsFailed => 'تعذر تحميل جنسيات السائقين للمعدة.';

  @override
  String get errLoadRespFailed => 'تعذر تحميل أسماء المسؤوليات.';

  @override
  String get errRequestAddFailed => 'فشل إنشاء/إضافة الطلب';

  @override
  String get requestCreated => 'تم إنشاء الطلب';

  @override
  String unitIndex(int index) {
    return 'الوحدة $index';
  }

  @override
  String get noImages => 'لا توجد صور';

  @override
  String get mapSearchHint => 'ابحث عن موقع…';

  @override
  String get mapNoResults => 'لا توجد نتائج';

  @override
  String get mapCancel => 'إلغاء';

  @override
  String get mapUseThisLocation => 'استخدام هذا الموقع';

  @override
  String get mapExpandTooltip => 'تكبير الخريطة';

  @override
  String get mapClear => 'مسح';

  @override
  String mapLatLabel(String value) {
    return 'خط العرض: $value';
  }

  @override
  String mapLngLabel(String value) {
    return 'خط الطول: $value';
  }

  @override
  String get actionLogin => 'تسجيل الدخول';

  @override
  String get actionLogout => 'تسجيل الخروج';

  @override
  String get sameDropoffForAll => 'استخدام نفس موقع التسليم لكل الوحدات';

  @override
  String errUnitAddress(int index) {
    return 'الوحدة $index: يرجى إدخال موقع التسليم';
  }

  @override
  String get infoCompleteProfileFirst => 'يرجى إكمال ملفك الشخصي أولًا.';

  @override
  String get leaveEmpty => 'اتركها فارغة لتكون 0%';

  @override
  String get errSelectEquipmentType => 'اختر نوع المعدّة';

  @override
  String get errSelectEquipmentFromList => 'اختر معدّة من القائمة';

  @override
  String get errSelectFactory => 'اختر المصنع';

  @override
  String get errEnterDescriptionEnOrAr => 'أدخل الوصف (بالإنجليزية أو العربية)';

  @override
  String get errSelectFuelResponsibility => 'اختر جهة تحمل الوقود';

  @override
  String get errSelectTransferType => 'اختر نوع النقل';

  @override
  String get errSelectTransferResponsibility => 'اختر جهة تحمل النقل';

  @override
  String get errSelectDriverTransport => 'اختر مسؤولية تنقل السائق';

  @override
  String get errSelectDriverFood => 'اختر مسؤولية طعام السائق';

  @override
  String get errSelectDriverHousing => 'اختر مسؤولية سكن السائق';

  @override
  String get errPricePerDayGtZero => 'أدخل سعر اليوم (> 0).';

  @override
  String get errPricePerHourGtZero => 'أدخل سعر الساعة (> 0).';

  @override
  String get errQuantityGteOne => 'أدخل الكمية (≥ 1).';

  @override
  String get errPleaseCompleteForm => 'يرجى إكمال الحقول المطلوبة';

  @override
  String get errDescRequiredEnOrAr => 'مطلوب (إنجليزي أو عربي)';

  @override
  String get errRequired => 'مطلوب';

  @override
  String get failedToLoadEquipment => 'فشل تحميل المعدّة';

  @override
  String get unsavedChangesTitle => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesBody => 'لديك تغييرات غير محفوظة. هل تريد حفظها قبل المغادرة؟';

  @override
  String get actionDiscard => 'تجاهل';

  @override
  String get pickIssueAndExpire => 'يرجى اختيار تاريخ الإصدار وتاريخ الانتهاء معًا.';

  @override
  String get chooseType => 'يرجى اختيار النوع.';

  @override
  String get chooseDocumentFile => 'يرجى اختيار ملف المستند.';

  @override
  String get nameEnRequired => 'الاسم (إنجليزي) *';

  @override
  String get nameArRequired => 'الاسم (عربي) *';

  @override
  String get typeDomain10Required => 'النوع *';

  @override
  String get issueDateRequired => 'تاريخ الإصدار *';

  @override
  String get expireDateRequired => 'تاريخ الانتهاء *';

  @override
  String get deleteImageTitle => 'حذف الصورة';

  @override
  String get deleteImageBody => 'هل تريد إزالة هذه الصورة من الإعلان؟';

  @override
  String get deleteTermQ => 'حذف الشرط؟';

  @override
  String get addDriver => 'إضافة سائق';

  @override
  String get editDriver => 'تعديل السائق';

  @override
  String get nationalityRequired => 'الجنسية *';

  @override
  String get deleteDriverQ => 'حذف السائق؟';

  @override
  String get addDriverFile => 'إضافة ملف للسائق';

  @override
  String get serverFileName => 'اسم الملف على الخادم';

  @override
  String get fileTypeIdRequired => 'معرّف نوع الملف *';

  @override
  String get startDateYmd => 'البداية yyyy-MM-dd';

  @override
  String get endDateYmd => 'النهاية yyyy-MM-dd';

  @override
  String get actionAdd => 'إضافة';

  @override
  String addFailedWithMsg(Object msg) {
    return 'فشل الإضافة: $msg';
  }

  @override
  String get fileDescriptionOptionalAr => 'وصف الملف بالعربي (اختياري)';

  @override
  String get fileDescriptionOptionalEn => 'وصف الملف بالانجليزي (اختياري)';

  @override
  String get required => 'إلزامي';

  @override
  String get previewPdf => 'معاينة PDF';

  @override
  String get open => 'فتح';

  @override
  String get pickAFileFirst => 'يرجى اختيار ورفع ملف أولاً';

  @override
  String get savingDots => 'جارٍ الحفظ…';

  @override
  String get tryAgain => 'حاول مرة اخرى';

  @override
  String get all => 'الجميع';

  @override
  String get sessionExpired => 'الرجاء اعادة تسجيل الدخول';

  @override
  String get home => 'الرئيسية';

  @override
  String get browse => 'تصفح';

  @override
  String get settings => 'الإعدادات';

  @override
  String get errorLoadStatusDomain => 'تعذّر تحميل أسماء الحالات.';

  @override
  String get errorInvalidRequestId => 'رمز الطلب غير صالح.';

  @override
  String get errorUnitHasNoDriverForNationality => 'يوجد وحدة بدون سائق متاح للجنسية المطلوبة.';

  @override
  String get errorUpdateFailedFlagFalse => 'فشل التحديث (القيمة Flag=false).';

  @override
  String get errorContractCreationFailed => 'فشل إنشاء العقد.';

  @override
  String get snackContractCreated => 'تم إنشاء العقد';

  @override
  String get labelVendor => 'المورّد';

  @override
  String get labelCustomer => 'العميل';

  @override
  String get labelIAmVendorQ => 'هل أنا المورّد؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get labelItem => 'العنصر';

  @override
  String get labelEquipmentId => 'معرّف المعدة';

  @override
  String get labelWeight => 'الوزن';

  @override
  String get respFuel => 'الوقود';

  @override
  String get respDriverFood => 'طعام السائق';

  @override
  String get respDriverHousing => 'سكن السائق';

  @override
  String get sectionStatusAcceptance => 'الحالة والموافقات';

  @override
  String get flagVendorAccepted => 'موافقة المورّد';

  @override
  String get flagCustomerAccepted => 'موافقة العميل';

  @override
  String get sectionNotes => 'ملاحظات';

  @override
  String get labelVendorNotes => 'ملاحظات المورّد';

  @override
  String get labelCustomerNotes => 'ملاحظات العميل';

  @override
  String get sectionAttachments => 'المرفقات';

  @override
  String get sectionMeta => 'بيانات إضافية';

  @override
  String get labelRequestId => 'رقم الطلب';

  @override
  String get labelRequestNo => 'رقم المرجع';

  @override
  String get labelCreatedAt => 'تاريخ الإنشاء';

  @override
  String get labelUpdatedAt => 'تاريخ التعديل';

  @override
  String fileType1(Object type) {
    return 'النوع $type';
  }

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String driverWithId(Object id) {
    return 'سائق رقم $id';
  }

  @override
  String get superAdmin_title => 'المشرف العام';

  @override
  String get superAdmin_tab_orgFiles => 'ملفات المؤسسات';

  @override
  String get superAdmin_tab_orgUsers => 'مستخدمو المؤسسات';

  @override
  String get superAdmin_tab_requestsOrders => 'الطلبات / الأوامر';

  @override
  String get superAdmin_tab_inactiveEquipments => 'معدات غير مفعّلة';

  @override
  String get superAdmin_tab_inactiveOrgs => 'مؤسسات غير مفعّلة';

  @override
  String get superAdmin_gate_signIn_title => 'يلزم تسجيل الدخول';

  @override
  String get superAdmin_gate_signIn_message => 'هذه الصفحة مخصصة لحسابات المشرف العام.';

  @override
  String get superAdmin_gate_notAvailable_title => 'غير متاح';

  @override
  String get superAdmin_gate_notAvailable_message => 'حسابك لا يملك صلاحية المشرف العام.';

  @override
  String get orgFiles_search_label => 'ابحث في ملفات المؤسسات';

  @override
  String get orgFiles_delete_title => 'حذف الملف؟';

  @override
  String orgFiles_delete_message(Object fileName) {
    return 'سيتم حذف \"$fileName\".';
  }

  @override
  String get orgFiles_empty => 'لا توجد ملفات للمؤسسات.';

  @override
  String get orgUsers_search_label => 'ابحث في مستخدمي المؤسسات';

  @override
  String get orgUsers_remove_title => 'إزالة مستخدم المؤسسة؟';

  @override
  String orgUsers_remove_message(Object orgId, Object userId) {
    return 'سيتم فك ارتباط المستخدم رقم #$userId بالمؤسسة رقم #$orgId.';
  }

  @override
  String get orgUsers_empty => 'لا يوجد مستخدمون للمؤسسات.';

  @override
  String get requests_search_label => 'ابحث في الطلبات / الأوامر';

  @override
  String requests_item_title(Object id) {
    return 'طلب رقم #$id';
  }

  @override
  String get requests_empty => 'لا توجد طلبات.';

  @override
  String get inactiveEquipments_search_label => 'ابحث في المعدات غير المفعّلة';

  @override
  String get inactiveEquipments_empty => 'لا توجد معدات غير مفعّلة.';

  @override
  String get inactiveOrgs_search_label => 'ابحث في المؤسسات غير المفعّلة';

  @override
  String get inactiveOrgs_empty => 'لا توجد مؤسسات غير مفعّلة.';

  @override
  String get action_signIn => 'تسجيل الدخول';

  @override
  String get action_back => 'رجوع';

  @override
  String get action_cancel => 'إلغاء';

  @override
  String get action_delete => 'حذف';

  @override
  String get action_remove => 'إزالة';

  @override
  String get action_previewOpen => 'عرض / فتح';

  @override
  String get action_activate => 'تفعيل';

  @override
  String get action_deactivate => 'إلغاء التفعيل';

  @override
  String get action_openOrganization => 'فتح المؤسسة';

  @override
  String get action_removeFromOrg => 'إزالة من المؤسسة';

  @override
  String get common_signedIn => 'تم تسجيل الدخول';

  @override
  String get common_updated => 'تم التحديث';

  @override
  String get common_updateFailed => 'فشل التحديث';

  @override
  String get common_deleted => 'تم الحذف';

  @override
  String get common_deleteFailed => 'فشل الحذف';

  @override
  String get common_removed => 'تمت الإزالة';

  @override
  String get common_removeFailed => 'فشلت الإزالة';

  @override
  String get common_typeToSearch => 'اكتب للبحث';

  @override
  String common_orgNumber(Object id) {
    return 'مؤسسة رقم #$id';
  }

  @override
  String get common_user => 'مستخدم';

  @override
  String get common_equipment => 'معدات';

  @override
  String get common_organization => 'مؤسسة';

  @override
  String get common_file => 'ملف';

  @override
  String get common_status => 'الحالة';

  @override
  String get common_active => 'مفعّل';

  @override
  String get common_inactive => 'غير مفعّل';

  @override
  String get common_expired => 'منتهي';

  @override
  String get common_activated => 'تم التفعيل';

  @override
  String get common_deactivated => 'تم الغاء التفعيل';

  @override
  String get superAdmin_tab_overview => 'نظرة عامة';

  @override
  String get superAdmin_tab_settings => 'الإعدادات';

  @override
  String get superAdmin_tab_auditLogs => 'سجل التدقيق';

  @override
  String get common_search => 'بحث';

  @override
  String get overview_totalOrgs => 'إجمالي المؤسسات';

  @override
  String get overview_totalEquipments => 'إجمالي المعدات';

  @override
  String get overview_totalUsers => 'إجمالي المستخدمين';

  @override
  String get overview_openRequests => 'الطلبات المفتوحة';

  @override
  String get overview_quick_createOrg => 'إنشاء مؤسسة';

  @override
  String get overview_quick_inviteUser => 'دعوة مستخدم';

  @override
  String get overview_quick_settings => 'فتح الإعدادات';

  @override
  String get overview_recentActivity => 'النشاط الأخير';

  @override
  String get settings_maintenanceMode => 'وضع الصيانة';

  @override
  String get settings_maintenanceMode_desc => 'إيقاف التطبيق مؤقتًا للمستخدمين.';

  @override
  String get settings_allowSignups => 'السماح بالتسجيل';

  @override
  String get settings_allowSignups_desc => 'السماح للمستخدمين الجدد بإنشاء حسابات.';

  @override
  String get settings_enableNotifications => 'تفعيل الإشعارات';

  @override
  String get settings_enableNotifications_desc => 'إرسال إشعارات النظام للمستخدمين.';

  @override
  String get settings_emptyOrError => 'تعذر تحميل الإعدادات.';

  @override
  String get audit_search_label => 'ابحث في سجل التدقيق';

  @override
  String get audit_empty => 'لا توجد سجلات تدقيق.';

  @override
  String get audit_filter_all => 'الكل';

  @override
  String get audit_filter_info => 'معلومات';

  @override
  String get audit_filter_warn => 'تحذير';

  @override
  String get audit_filter_error => 'خطأ';

  @override
  String get search_hint => 'اكتب للبحث…';

  @override
  String get search_noResults => 'لا توجد نتائج.';

  @override
  String common_statusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String get common_organizations => 'المؤسسات';

  @override
  String get common_users => 'المستخدمون';

  @override
  String get common_equipments => 'المعدات';

  @override
  String get common_requests => 'الطلبات';

  @override
  String get action_save => 'حفظ';

  @override
  String get common_saved => 'تم الحفظ بنجاح.';

  @override
  String get common_saveFailed => 'فشل الحفظ.';

  @override
  String get action_close => 'إغلاق';

  @override
  String get details_org_title => 'تفاصيل المؤسسة';

  @override
  String get details_equipment_title => 'تفاصيل المعدّة';

  @override
  String get common_details => 'التفاصيل';

  @override
  String get common_id => 'المعرّف';

  @override
  String get common_english => 'الإنجليزية';

  @override
  String get common_arabic => 'العربية';

  @override
  String get details_notFound_org => 'تعذر تحميل تفاصيل المؤسسة.';

  @override
  String get details_notFound_equipment => 'تعذر تحميل تفاصيل المعدّة.';

  @override
  String get common_image => 'صورة';

  @override
  String get common_images => 'صور';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get noCalendarEvents => 'لا توجد أحداث في التقويم.';

  @override
  String event_eventOnDate(String event, String date) {
    return '$event on $date';
  }

  @override
  String get calendarSubtitle => 'الأحداث والمواعيد الهامة';

  @override
  String get requestCalendar => 'تقويم الطلبات';

  @override
  String get filterByEquipment => 'تصفية حسب المعدات';

  @override
  String get filterByDate => 'تصفية حسب التاريخ';

  @override
  String get noRequests => 'لا توجد طلبات';

  @override
  String get selectEquipment => 'اختر المعدات';

  @override
  String get noEquipmentFound => 'لا توجد معدات';

  @override
  String get failedToLoadEquipments => 'فشل تحميل المعدات';

  @override
  String get clearFilter => 'مسح التصفية';
}
