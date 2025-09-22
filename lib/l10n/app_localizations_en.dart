// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HeavyRent';

  @override
  String get tooltipLogin => 'Login';

  @override
  String get tooltipLogout => 'Logout';

  @override
  String get admin => 'Admin';

  @override
  String get signedIn => 'Signed in';

  @override
  String get signedOut => 'Signed out';

  @override
  String get heroTitle => 'Heavy gear, light work';

  @override
  String get heroSubtitle => 'Rent certified machines with drivers, on-demand.';

  @override
  String get findEquipment => 'Find equipment';

  @override
  String get popularEquipment => 'Popular equipment';

  @override
  String get seeMore => 'See more';

  @override
  String get couldNotLoadEquipment => 'Could not load equipment';

  @override
  String get retry => 'Retry';

  @override
  String get noEquipmentYet => 'No equipment yet.';

  @override
  String get rent => 'Rent';

  @override
  String fromPerDay(String price) {
    return 'From $price / day';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'Arabic';

  @override
  String get appTitle => 'HeavyRent';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionRentNow => 'Rent now';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionFilter => 'Filter';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get searchHint => 'Search equipment, brands, cities...';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get otp => 'OTP Code';

  @override
  String get sendCode => 'Send code';

  @override
  String get verifyCode => 'Verify';

  @override
  String get withDriver => 'With driver';

  @override
  String pricePerDay(String price) {
    return '$price / day';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String validationRequired(String field) {
    return '$field is required';
  }

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String msgOtpSent(String phone) {
    return 'We sent a code to $phone';
  }

  @override
  String get snackSaved => 'Saved';

  @override
  String get snackError => 'Something went wrong';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get homeHeadline => 'Heavy gear, light work';

  @override
  String get homeSub => 'Rent certified machines on‑demand';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get filters => 'Filters';

  @override
  String get filterBrand => 'Brand';

  @override
  String get filterCity => 'City';

  @override
  String get filterPriceDay => 'Price/Day';

  @override
  String get filterHasCerts => 'Has certificates';

  @override
  String get filterDistance => 'Distance pricing';

  @override
  String get filterApply => 'Apply Filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get emptyTitle => 'No results';

  @override
  String get emptyBody => 'Try adjusting filters or search keywords';

  @override
  String get appSettings => 'App settings';

  @override
  String get selectTime => 'Select time';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get test => 'Test';

  @override
  String get testNotificationMessage => 'This is a test notification';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get inAppBanners => 'In-app banners';

  @override
  String get emailUpdates => 'Email updates';

  @override
  String get sound => 'Sound';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get quietHoursHint => 'During quiet hours, sounds are muted. (Demo—wire to your push provider later.)';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get notAvailableTitle => 'Not available';

  @override
  String get signInRequiredTitle => 'Sign in required';

  @override
  String get restrictedPageMessage => 'This page is only available for accounts with user type #17 or #20.';

  @override
  String get signInPrompt => 'Please sign in to continue.';

  @override
  String get accountTitle => 'Account';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusIncomplete => 'Incomplete';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'You can sign in again anytime.';

  @override
  String get cancel => 'Cancel';

  @override
  String get completeYourAccountBody => 'Complete your account to unlock Organization and My equipment.';

  @override
  String get completeAction => 'Complete';

  @override
  String get accountSection => 'Account';

  @override
  String get manageSection => 'Manage';

  @override
  String get activitySection => 'Activity';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Your personal & company details';

  @override
  String get appSettingsSubtitle => 'Theme, language, notifications';

  @override
  String get organizationTitle => 'Organization';

  @override
  String get organizationSubtitle => 'Company info & compliance';

  @override
  String get myEquipmentTitle => 'My equipment';

  @override
  String get myEquipmentSubtitle => 'View and manage your fleet';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get requestsSubtitle => 'Manage your requests';

  @override
  String get superAdminTitle => 'Super Admin';

  @override
  String get superAdminSubtitle => 'Open super admin panel (debug)';

  @override
  String get contractsTitle => 'Contracts';

  @override
  String get contractsSubtitle => 'Pending, open, finished, closed';

  @override
  String get ordersHistoryTitle => 'Orders (history)';

  @override
  String get ordersHistorySubtitle => 'Past orders & receipts';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get codeLabel => 'Code';

  @override
  String get codeHint => '966';

  @override
  String get mobile9DigitsLabel => 'Mobile (9 digits)';

  @override
  String get mobile9DigitsHint => '5XX XXX XXX';

  @override
  String get enterNineDigits => 'Enter 9 digits';

  @override
  String get resendCode => 'Resend code';

  @override
  String devOtpHint(String code) {
    return 'DEV OTP: $code';
  }

  @override
  String get enterCodeTitle => 'Enter code';

  @override
  String get verifyAndContinue => 'Verify & continue';

  @override
  String get didntGetItTapResend => 'Didn\'t get it? Tap \"Resend code\".';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInWithMobileBlurb => 'Sign in with your mobile number.\nFast, secure, OTP-based login.';

  @override
  String get neverShareNumber => 'We’ll never share your number.';

  @override
  String get otpSent => 'OTP sent';

  @override
  String get couldNotStartVerification => 'Could not start verification';

  @override
  String get enterFourDigitCode => 'Enter the 4-digit code';

  @override
  String get invalidOrExpiredCode => 'Invalid or expired code';

  @override
  String get fullName => 'Full name';

  @override
  String get passwordKeep => 'Password';

  @override
  String validationMinChars(int min) {
    return 'Minimum $min characters';
  }

  @override
  String get actionSaveChanges => 'Save changes';

  @override
  String get actionReset => 'Reset';

  @override
  String get profileCompletePrompt => 'Complete your profile';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get couldNotSaveProfile => 'Could not save profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get orgTitle => 'Organization';

  @override
  String get orgCreateTitle => 'Create organization';

  @override
  String get orgType => 'Type';

  @override
  String get orgStatus => 'Status';

  @override
  String get orgNameArabic => 'Name (Arabic)';

  @override
  String get orgNameEnglish => 'Name (English)';

  @override
  String get orgBriefArabic => 'Brief (Arabic)';

  @override
  String get orgBriefEnglish => 'Brief (English)';

  @override
  String get orgCountry => 'Country';

  @override
  String get orgCity => 'City';

  @override
  String get orgAddress => 'Address';

  @override
  String get orgCrNumber => 'C.R. Number';

  @override
  String get orgVatNumber => 'VAT Number';

  @override
  String get orgMainMobile => 'Main mobile';

  @override
  String get orgSecondMobile => 'Second mobile';

  @override
  String get orgMainEmail => 'Main email';

  @override
  String get orgSecondEmail => 'Second email';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionSave => 'Save';

  @override
  String get edit => 'edit';

  @override
  String get orgFilesTitle => 'Files • Attachments';

  @override
  String get orgAddFile => 'Add file';

  @override
  String get orgCreateToManageFiles => 'Create organization to manage files.';

  @override
  String get orgNoFilesYet => 'No files yet.';

  @override
  String get attachmentTitle => 'Attachment';

  @override
  String get fileType => 'File type';

  @override
  String get addFileNameRequired => 'Add file name *';

  @override
  String get pickFile => 'Pick file *';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get issueDate => 'Issue date';

  @override
  String get expireDate => 'Expire date';

  @override
  String get image => 'Image';

  @override
  String get active => 'Active';

  @override
  String get expired => 'Expired';

  @override
  String get orgEnterNameMin3 => 'Please enter a name (≥ 3 chars)';

  @override
  String get orgChooseTypeStatusCity => 'Please choose Status, Type and City';

  @override
  String get createFailed => 'Create failed';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get orgCreated => 'Organization created';

  @override
  String get orgUpdated => 'Organization updated';

  @override
  String get orgCouldNotSave => 'Could not save organization';

  @override
  String get failedToLoadOrganization => 'Failed to load organization';

  @override
  String get orgCreateFirst => 'Create organization first';

  @override
  String get chooseFileType => 'Choose a file type';

  @override
  String get pickFileNameRequired => 'Pick a file — name is required';

  @override
  String get fileAdded => 'File added';

  @override
  String get fileUpdated => 'File updated';

  @override
  String get couldNotSaveFile => 'Could not save file';

  @override
  String get deleteFileTitle => 'Delete file';

  @override
  String get deleteFileBody => 'Are you sure you want to delete this file?';

  @override
  String get delete => 'Delete';

  @override
  String get deleteMissingId => 'Could not delete: missing file id';

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get couldNotDeleteFile => 'Could not delete file';

  @override
  String get myEquipSignInBody => 'You need to sign in to manage your equipment.';

  @override
  String get orgNeededTitle => 'Organization needed';

  @override
  String get orgNeededBody => 'Add your organization before listing or managing equipment.';

  @override
  String get actionAddOrganization => 'Add organization';

  @override
  String get submittedMayTakeMoment => 'Submitted. It may take a moment to appear.';

  @override
  String get cantAddEquipment => 'Can’t add equipment';

  @override
  String get actionOk => 'OK';

  @override
  String unexpectedErrorWithMsg(String msg) {
    return 'Unexpected error: $msg';
  }

  @override
  String get actionAddEquipment => 'Add equipment';

  @override
  String failedToLoadYourEquipment(String error) {
    return 'Failed to load your equipment.\n$error';
  }

  @override
  String get noEquipmentYetTapAdd => 'No equipment yet. Tap “Add equipment” to create one.';

  @override
  String get openAsCustomerToRent => 'Open as customer to rent';

  @override
  String get signInRequired => 'Sign In Required';

  @override
  String get equipSettingsTitle => 'Equipment settings';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabImages => 'Images';

  @override
  String get tabTerms => 'Terms';

  @override
  String get tabDrivers => 'Drivers';

  @override
  String get tabCertificates => 'Certificates';

  @override
  String get basicInfo => 'Basic info';

  @override
  String get nameEn => 'Name (EN)';

  @override
  String get nameAr => 'Name (AR)';

  @override
  String get exampleExcavator => 'e.g. Excavator 22T';

  @override
  String get exampleExcavatorAr => 'e.g. حفار ٢٢ طن';

  @override
  String get pricing => 'Pricing';

  @override
  String get pricePerHour => 'Price / hour';

  @override
  String downPaymentPct(Object pct, Object amount) {
    return 'Down payment: $pct% → $amount';
  }

  @override
  String get quantityAndStatus => 'Quantity & Status';

  @override
  String get quantity => 'Quantity';

  @override
  String get equipmentWeight => 'Equipment weight';

  @override
  String get activeVisible => 'Active (visible)';

  @override
  String get inactiveHidden => 'Inactive (hidden)';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get noteSendsFullObject => 'Note: saving sends a full object (IDs only for domains) to PUT /Equipment/update.';

  @override
  String get saved => 'Saved';

  @override
  String saveFailedWithMsg(Object msg) {
    return 'Save failed: $msg';
  }

  @override
  String get uploading => 'Uploading…';

  @override
  String get actionAddImage => 'Add image';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get noImagesYet => 'No images yet.';

  @override
  String get imageUploaded => 'Image uploaded';

  @override
  String uploadFailedWithMsg(Object msg) {
    return 'Upload failed: $msg';
  }

  @override
  String get imageDeleted => 'Image deleted';

  @override
  String deleteFailedWithMsg(Object msg) {
    return 'Delete failed: $msg';
  }

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAddTerm => 'Add term';

  @override
  String get actionSaveOrder => 'Save order';

  @override
  String get noTermsYetCreateFirst => 'No terms yet. Click “Add term” to create your first item.';

  @override
  String get addTerm => 'Add term';

  @override
  String get editTerm => 'Edit term';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get order => 'Order';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get deleted => 'Deleted';

  @override
  String get orderSaved => 'Order saved';

  @override
  String orderSaveFailedWithMsg(Object msg) {
    return 'Order save failed: $msg';
  }

  @override
  String get driver => 'Driver';

  @override
  String get nationalityIdLabel => 'Nationality id:';

  @override
  String get actionAddDriver => 'Add driver';

  @override
  String get noDriversYet => 'No drivers yet.';

  @override
  String get noFiles => 'No files';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get actionAddFile => 'Add file';

  @override
  String get deleteFileQ => 'Delete file?';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get fileAndTypeRequired => 'File and Type ID are required';

  @override
  String get actionAddCertificate => 'Add certificate';

  @override
  String get noCertificatesYet => 'No certificates yet.';

  @override
  String get addCertificate => 'Add certificate';

  @override
  String get editCertificate => 'Edit certificate';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get pdfSelected => 'PDF selected';

  @override
  String get nameEnReq => 'Name (EN) *';

  @override
  String get nameArReq => 'Name (AR) *';

  @override
  String get typeDomain10Req => 'Type (Domain 10) *';

  @override
  String get issueDateReq => 'Issue date *';

  @override
  String get expireDateReq => 'Expire date *';

  @override
  String get isImage => 'Is image';

  @override
  String get saving => 'Saving…';

  @override
  String get pleasePickIssueAndExpire => 'Please pick both Issue and Expire dates.';

  @override
  String get pleaseChooseType => 'Please choose a Type.';

  @override
  String get pleaseChooseDocument => 'Please choose a document file.';

  @override
  String get deleteCertificateQ => 'Delete certificate?';

  @override
  String get noPastOrdersYet => 'No past orders yet';

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get signInToViewRequests => 'Sign in to view your requests';

  @override
  String get signInToViewRequestsBody => 'You need to be logged in to see your request history and details.';

  @override
  String get failedToLoadRequests => 'Failed to load requests';

  @override
  String get noRequestsYet => 'No requests yet.';

  @override
  String get requestNumber => 'Request #';

  @override
  String get asVendor => 'As Vendor';

  @override
  String get asCustomer => 'As Customer';

  @override
  String get daysSuffix => 'days';

  @override
  String get requestDetailsTitle => 'Request details';

  @override
  String get failedToLoadRequest => 'Failed to load request';

  @override
  String get sectionDuration => 'Duration';

  @override
  String get sectionPriceBreakdown => 'Price breakdown';

  @override
  String get priceBase => 'Base';

  @override
  String get priceDistance => 'Distance';

  @override
  String get priceVat => 'VAT';

  @override
  String get priceTotal => 'Total';

  @override
  String get priceDownPayment => 'Down payment';

  @override
  String get sectionAssignDrivers => 'Assign drivers';

  @override
  String get errorLoadDriverLocations => 'Could not load driver locations.';

  @override
  String get emptyNoDriverLocations => 'No driver locations for this request.';

  @override
  String get errorNoDriversForNationality => 'Some units have no available drivers for the requested nationality.';

  @override
  String get errorAssignDriverEachUnit => 'Select a driver for every unit.';

  @override
  String get actionCreateContract => 'Create contract';

  @override
  String get creatingEllipsis => 'Creating…';

  @override
  String get actionCancelRequest => 'Cancel request';

  @override
  String get unitLabel => 'Unit';

  @override
  String get requestedNationality => 'Requested nationality';

  @override
  String get dropoffLabel => 'Drop-off';

  @override
  String get coordinatesLabel => 'Coords';

  @override
  String get emptyNoDriversForThisNationality => 'No drivers available for this nationality.';

  @override
  String get labelAssignDriverFiltered => 'Assign driver (filtered by nationality)';

  @override
  String get hintSelectDriver => 'Select driver';

  @override
  String get orderNumber => 'Order #';

  @override
  String get requestListLeadingLabel => 'Request #';

  @override
  String get currencySar => 'SAR';

  @override
  String get pending => 'Pending';

  @override
  String get daySingular => 'day';

  @override
  String get toDateSep => 'to';

  @override
  String get detailsCopied => 'Details copied';

  @override
  String get requestSubmittedTitle => 'Request submitted';

  @override
  String get successTitle => 'Success!';

  @override
  String get numberPendingChip => 'Number pending';

  @override
  String get requestSubmittedBody => 'Your request has been submitted.';

  @override
  String get requestLabel => 'Request:';

  @override
  String get requestHashPrefix => 'Request #';

  @override
  String get statusLabel => 'Status';

  @override
  String get dateRangeLabel => 'Date range';

  @override
  String get totalLabel => 'Total';

  @override
  String get actionCopyDetails => 'Copy details';

  @override
  String get actionDone => 'Done';

  @override
  String daysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days',
      one: '# day',
    );
    return '$_temp0';
  }

  @override
  String get equipmentTitle => 'Equipment';

  @override
  String get searchByDescriptionHint => 'Search by description…';

  @override
  String get failedToLoadEquipmentList => 'Failed to load equipment list';

  @override
  String get noResults => 'No results';

  @override
  String get equipEditorTitleNew => 'New equipment';

  @override
  String get actionContinue => 'Continue';

  @override
  String get errorCouldNotLoadFactories => 'Could not load factories';

  @override
  String get errorChooseEquipmentType => 'Choose an equipment type';

  @override
  String get errorChooseFactory => 'Choose a factory';

  @override
  String get errorEnterDescription => 'Enter a description (EN or AR)';

  @override
  String get errorFailedToLoadOptions => 'Failed to load options';

  @override
  String get sectionType => 'Type';

  @override
  String get labelEquipmentList => 'Equipment list';

  @override
  String get selectedPrefix => 'Selected:';

  @override
  String get sectionOwnershipStatus => 'Ownership & Status';

  @override
  String get labelFactory => 'Factory';

  @override
  String get hintSelectFactory => 'Select a factory';

  @override
  String get tooltipRefreshFactories => 'Refresh factories';

  @override
  String get labelStatusD11 => 'Status (Domain 11)';

  @override
  String get sectionLogistics => 'Logistics';

  @override
  String get labelCategoryD9 => 'Category (Domain 9)';

  @override
  String get labelFuelRespD7 => 'Fuel responsibility (Domain 7)';

  @override
  String get labelTransferTypeD8 => 'Transfer type (Domain 8)';

  @override
  String get labelTransferRespD7 => 'Transfer responsibility (Domain 7)';

  @override
  String get sectionDriverRespD7 => 'Driver responsibilities (Domain 7)';

  @override
  String get labelTransport => 'Transport';

  @override
  String get labelFood => 'Food';

  @override
  String get labelHousing => 'Housing';

  @override
  String get sectionDescriptions => 'Descriptions';

  @override
  String get labelDescEnglish => 'Description (English)';

  @override
  String get hintDescEnglish => 'e.g. Excavator 22T';

  @override
  String get labelDescArabic => 'Description (Arabic)';

  @override
  String get hintDescArabic => 'e.g. 22T Excavator (Arabic)';

  @override
  String get sectionPricing => 'Pricing';

  @override
  String get labelPricePerDay => 'Price per day';

  @override
  String get hintPricePerDay => 'e.g. 1600';

  @override
  String get labelPricePerHour => 'Price per hour';

  @override
  String get hintPricePerHour => 'e.g. 160';

  @override
  String ruleHoursPerDayAndDp(Object hours, Object percent) {
    return 'Rule: 1 day = $hours hours. Down payment = $percent%.';
  }

  @override
  String downPaymentAuto(Object amount) {
    return 'Down payment (auto): $amount';
  }

  @override
  String get sectionQuantity => 'Quantity';

  @override
  String get labelQuantityAlsoAvailable => 'Quantity (also used as Available)';

  @override
  String get hintQuantity => 'e.g. 1';

  @override
  String get noteAvailableReserved => 'Available = Quantity, Reserved starts at 0 (both updated later).';

  @override
  String get unnamedFactory => 'Unnamed factory';

  @override
  String get contractTitle => 'Contract';

  @override
  String get actionOpenContractSheet => 'Open Contract Sheet';

  @override
  String get actionPrint => 'Print';

  @override
  String get printingStubMessage => 'Printing stub — wire up printing/pdf here.';

  @override
  String get errorFailedToLoadContractDetails => 'Failed to load contract details';

  @override
  String get errorNoContractSlice => 'No contract slice found/created.';

  @override
  String get rentalAgreementHeader => 'RENTAL AGREEMENT';

  @override
  String contractNumber(Object num) {
    return 'Contract #$num';
  }

  @override
  String get sectionParties => 'Parties';

  @override
  String get sectionRequestSummary => 'Request Summary';

  @override
  String get sectionEquipment => 'Equipment';

  @override
  String get sectionResponsibilities => 'Responsibilities (Domain 7)';

  @override
  String get sectionTerms => 'Terms';

  @override
  String get sectionDriverAssignments => 'Driver Assignments (per requested unit)';

  @override
  String get sectionSignatures => 'Signatures';

  @override
  String get vendorLabel => 'Vendor';

  @override
  String get customerLabel => 'Customer';

  @override
  String get requestNumberLabel => 'Request No.';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get daysLabel => 'Days';

  @override
  String get rentPerDayLabel => 'Rent / Day';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get vatLabel => 'VAT';

  @override
  String get downPaymentLabel => 'Down Payment';

  @override
  String get titleLabel => 'Title';

  @override
  String get categoryLabel => 'Category';

  @override
  String get fuelResponsibilityLabel => 'Fuel Responsibility';

  @override
  String get driverFoodLabel => 'Driver Food';

  @override
  String get driverHousingLabel => 'Driver Housing';

  @override
  String get driverTransportLabel => 'Driver Transport';

  @override
  String responsibilityValue(Object label, Object id) {
    return '$label (ID #$id)';
  }

  @override
  String get termDownPayment => 'Down payment before mobilization; remaining as per agreed schedule.';

  @override
  String get termManufacturerGuidelines => 'All equipment to be used according to manufacturer guidelines.';

  @override
  String get termCustomerSiteAccess => 'Customer is responsible for site access and safe working environment.';

  @override
  String get termLiability => 'Damages and liability per company terms and applicable law.';

  @override
  String get equipmentTermsHeading => 'Equipment Terms:';

  @override
  String get noDriverLocations => 'No driver locations found for this request.';

  @override
  String get requestedNationalityLabel => 'Requested nationality';

  @override
  String get coordsLabel => 'Coords';

  @override
  String get assignedDriverLabel => 'Assigned driver';

  @override
  String get companyLogo => 'VISION CIT';

  @override
  String detailHash(Object id) {
    return 'Detail #$id';
  }

  @override
  String get contractSheetTitle => 'Contract Sheet';

  @override
  String contractChip(Object id) {
    return 'Contract #$id';
  }

  @override
  String requestChip(Object id) {
    return 'Req #$id';
  }

  @override
  String qtyChip(int qty) {
    return 'Qty: $qty';
  }

  @override
  String dateRangeChip(Object from, Object to) {
    return '$from → $to';
  }

  @override
  String get roleVendor => 'Role: Vendor';

  @override
  String get roleCustomer => 'Role: Customer';

  @override
  String get rowNothingToSave => 'Nothing to save for this row.';

  @override
  String rowLabel(Object unit, Object date) {
    return 'u$unit $date';
  }

  @override
  String rowSaved(Object label) {
    return 'Saved ($label).';
  }

  @override
  String rowSaveFailed(Object label) {
    return 'Save failed ($label).';
  }

  @override
  String get endpoint405Noop => 'Update endpoint not enabled (405). Nothing changed on the server.';

  @override
  String get savedChip => 'Saved';

  @override
  String get unsavedChip => 'Unsaved';

  @override
  String get plannedLabel => 'Planned';

  @override
  String get actualLabel => 'Actual';

  @override
  String get overtimeLabel => 'Overtime';

  @override
  String get customerNoteLabel => 'Customer note';

  @override
  String get vendorNoteLabel => 'Vendor note';

  @override
  String get savingEllipsis => 'Saving…';

  @override
  String get infoCreateActivateOrg => 'Please create/activate your Organization first.';

  @override
  String get noContractsYet => 'No contracts yet.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotificationsYet => 'No notifications yet.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get searchChats => 'Search chats';

  @override
  String get noChatsYet => 'No chats yet.';

  @override
  String chatTitle(Object id) {
    return 'Chat #$id';
  }

  @override
  String get threadActionsSoon => 'Thread actions coming soon';

  @override
  String get messageHint => 'Message';

  @override
  String get actionSend => 'Send';

  @override
  String get sendingEllipsis => 'Sending…';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutesShort(Object m) {
    return '${m}m';
  }

  @override
  String timeHoursShort(Object h) {
    return '${h}h';
  }

  @override
  String timeDaysShort(Object d) {
    return '${d}d';
  }
}
