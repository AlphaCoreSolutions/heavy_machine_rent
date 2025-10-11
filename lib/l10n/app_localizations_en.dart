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
  String get typeDomain10Req => 'Type*';

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
  String get labelStatusD11 => 'Status';

  @override
  String get sectionLogistics => 'Logistics';

  @override
  String get labelCategoryD9 => 'Category';

  @override
  String get labelFuelRespD7 => 'Fuel responsibility';

  @override
  String get labelTransferTypeD8 => 'Transfer type';

  @override
  String get labelTransferRespD7 => 'Transfer responsibility';

  @override
  String get sectionDriverRespD7 => 'Driver responsibilities';

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
  String get sectionResponsibilities => 'Responsibilities';

  @override
  String get sectionTerms => 'Terms & Conditions';

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

  @override
  String get title_equipmentDetails => 'Equipment details';

  @override
  String get msg_failedLoadEquipment => 'Failed to load equipment';

  @override
  String get label_availability => 'Availability';

  @override
  String get label_rentFrom => 'Rent Date (From)';

  @override
  String get hint_yyyyMMdd => 'YYYY-MM-DD';

  @override
  String get label_returnTo => 'Return Date (To)';

  @override
  String pill_days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get label_expectedKm => 'Expected distance (km)';

  @override
  String mini_pricePerKm(Object currency, Object price) {
    return '$currency $price / km';
  }

  @override
  String get label_quantity => 'Quantity';

  @override
  String get label_requestedQty => 'Requested quantity';

  @override
  String mini_available(Object count) {
    return 'Available: $count';
  }

  @override
  String get label_driverLocations => 'Driver Locations';

  @override
  String get msg_loadingNats => 'Loading available driver nationalities…';

  @override
  String get msg_noNats => 'No driver nationalities available for this equipment.';

  @override
  String get label_driverNationality => 'Driver nationality *';

  @override
  String get label_dropoffAddress => 'Drop-off address';

  @override
  String get label_dropoffLat => 'Drop-off latitude *';

  @override
  String get label_dropoffLon => 'Drop-off longitude *';

  @override
  String get label_notes => 'Notes';

  @override
  String chip_available(Object count) {
    return 'Available: $count';
  }

  @override
  String get label_priceBreakdown => 'Price breakdown';

  @override
  String get row_perUnit => 'Per unit';

  @override
  String row_base(Object days, Object price) {
    return 'Base ($price × $days day)';
  }

  @override
  String row_distance(Object km, Object pricePerKm) {
    return 'Distance ($pricePerKm × $km km)';
  }

  @override
  String row_vat(Object rate) {
    return 'VAT $rate%';
  }

  @override
  String get row_perUnitTotal => 'Per-unit total';

  @override
  String row_qtyTimes(Object qty) {
    return '× Quantity ($qty)';
  }

  @override
  String get row_subtotal => 'Subtotal';

  @override
  String get row_vatOnly => 'VAT';

  @override
  String get row_total => 'Total';

  @override
  String get row_downPayment => 'Down payment';

  @override
  String get btn_submit => 'Submit request';

  @override
  String get btn_submitting => 'Submitting…';

  @override
  String row_fuel(Object value) {
    return 'Fuel: $value';
  }

  @override
  String get err_chooseDates => 'Please choose dates';

  @override
  String get info_signInFirst => 'Please sign in first';

  @override
  String get err_qtyMin => 'Quantity must be at least 1';

  @override
  String err_qtyAvail(Object count) {
    return 'Only $count piece(s) available';
  }

  @override
  String err_unitSelectNat(Object index) {
    return 'Unit $index: Select a nationality';
  }

  @override
  String err_unitLatLng(Object index) {
    return 'Unit $index: Drop-off lat/long required';
  }

  @override
  String get err_vendorMissing => 'Vendor not found for this equipment.';

  @override
  String get info_createOrg => 'Please create/activate your Organization first.';

  @override
  String get err_loadNats => 'Could not load equipment driver nationalities.';

  @override
  String get err_loadResp => 'Could not load responsibility names.';

  @override
  String get equipDetailsTitle => 'Equipment details';

  @override
  String get msgFailedLoadEquipment => 'Failed to load equipment';

  @override
  String get labelAvailability => 'Availability';

  @override
  String get labelRentFrom => 'Rent Date (From)';

  @override
  String get hintYyyyMmDd => 'YYYY-MM-DD';

  @override
  String get labelReturnTo => 'Return Date (To)';

  @override
  String pillDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get labelExpectedKm => 'Expected distance (km)';

  @override
  String miniPricePerKm(String currency, String price) {
    return '$currency $price / km';
  }

  @override
  String get labelQuantity => 'Quantity';

  @override
  String get labelRequestedQty => 'Requested quantity';

  @override
  String miniAvailable(int count) {
    return 'Available: $count';
  }

  @override
  String get labelDriverLocations => 'Driver Locations';

  @override
  String get msgLoadingNats => 'Loading available driver nationalities…';

  @override
  String get msgNoNats => 'No driver nationalities available for this equipment.';

  @override
  String get labelDriverNationality => 'Driver nationality';

  @override
  String get labelDropoffAddress => 'Drop-off address';

  @override
  String get labelDropoffLat => 'Drop-off latitude *';

  @override
  String get labelDropoffLon => 'Drop-off longitude *';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelPriceBreakdown => 'Price breakdown';

  @override
  String get rowPerUnit => 'Per unit';

  @override
  String rowBase(String price, String days) {
    return 'Base ($price × $days day)';
  }

  @override
  String rowDistance(String pricePerKm, String km) {
    return 'Distance ($pricePerKm × $km km)';
  }

  @override
  String rowVat(String rate) {
    return 'VAT $rate%';
  }

  @override
  String get rowPerUnitTotal => 'Per-unit total';

  @override
  String rowQtyTimes(int qty) {
    return '× Quantity ($qty)';
  }

  @override
  String get rowSubtotal => 'Subtotal';

  @override
  String get rowVatOnly => 'VAT';

  @override
  String get rowTotal => 'Total';

  @override
  String get rowDownPayment => 'Down payment';

  @override
  String get btnSubmitting => 'Submitting…';

  @override
  String get btnSubmit => 'Submit request';

  @override
  String rowFuel(String value) {
    return 'Fuel: $value';
  }

  @override
  String get errChooseDates => 'Please choose dates';

  @override
  String get infoSignInFirst => 'Please sign in first';

  @override
  String get errQtyMin => 'Quantity must be at least 1';

  @override
  String errQtyAvail(int count) {
    return 'Only $count piece(s) available';
  }

  @override
  String errUnitSelectNat(int index) {
    return 'Unit $index: Select a nationality';
  }

  @override
  String errUnitLatLng(int index) {
    return 'Unit $index: Drop-off lat/long required';
  }

  @override
  String get errVendorMissing => 'Vendor not found for this equipment.';

  @override
  String get infoCreateOrgFirst => 'Please create/activate your Organization first.';

  @override
  String get errLoadNatsFailed => 'Could not load equipment driver nationalities.';

  @override
  String get errLoadRespFailed => 'Could not load responsibility names.';

  @override
  String get errRequestAddFailed => 'Request/add failed';

  @override
  String get requestCreated => 'Request created';

  @override
  String unitIndex(int index) {
    return 'Unit $index';
  }

  @override
  String get noImages => 'No images';

  @override
  String get mapSearchHint => 'Search a place…';

  @override
  String get mapNoResults => 'No results';

  @override
  String get mapCancel => 'Cancel';

  @override
  String get mapUseThisLocation => 'Use this location';

  @override
  String get mapExpandTooltip => 'Expand map';

  @override
  String get mapClear => 'Clear';

  @override
  String mapLatLabel(String value) {
    return 'Lat: $value';
  }

  @override
  String mapLngLabel(String value) {
    return 'Lng: $value';
  }

  @override
  String get actionLogin => 'Login';

  @override
  String get actionLogout => 'Logout';

  @override
  String get sameDropoffForAll => 'Same Drop-off Location';

  @override
  String errUnitAddress(int index) {
    return 'Unit $index: please enter the drop-off address';
  }

  @override
  String get infoCompleteProfileFirst => 'Please complete your profile first.';

  @override
  String get leaveEmpty => 'Leave Empty For 0%';

  @override
  String get errSelectEquipmentType => 'Select an equipment type';

  @override
  String get errSelectEquipmentFromList => 'Select an equipment from the list';

  @override
  String get errSelectFactory => 'Select a factory';

  @override
  String get errEnterDescriptionEnOrAr => 'Enter a description (English or Arabic)';

  @override
  String get errSelectFuelResponsibility => 'Select fuel responsibility';

  @override
  String get errSelectTransferType => 'Select transfer type';

  @override
  String get errSelectTransferResponsibility => 'Select transfer responsibility';

  @override
  String get errSelectDriverTransport => 'Select driver transport responsibility';

  @override
  String get errSelectDriverFood => 'Select driver food responsibility';

  @override
  String get errSelectDriverHousing => 'Select driver housing responsibility';

  @override
  String get errPricePerDayGtZero => 'Enter price per day (> 0).';

  @override
  String get errPricePerHourGtZero => 'Enter price per hour (> 0).';

  @override
  String get errQuantityGteOne => 'Enter quantity (≥ 1).';

  @override
  String get errPleaseCompleteForm => 'Please complete the form';

  @override
  String get errDescRequiredEnOrAr => 'Required (EN or AR)';

  @override
  String get errRequired => 'Required';

  @override
  String get failedToLoadEquipment => 'Failed to load equipment';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesBody => 'You have unsaved changes. Save them before leaving?';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get pickIssueAndExpire => 'Please pick both Issue and Expire dates.';

  @override
  String get chooseType => 'Please choose a Type.';

  @override
  String get chooseDocumentFile => 'Please choose a document file.';

  @override
  String get nameEnRequired => 'Name (EN) *';

  @override
  String get nameArRequired => 'Name (AR) *';

  @override
  String get typeDomain10Required => 'Type *';

  @override
  String get issueDateRequired => 'Issue date *';

  @override
  String get expireDateRequired => 'Expire date *';

  @override
  String get deleteImageTitle => 'Delete image';

  @override
  String get deleteImageBody => 'Remove this image from the listing?';

  @override
  String get deleteTermQ => 'Delete term?';

  @override
  String get addDriver => 'Add driver';

  @override
  String get editDriver => 'Edit driver';

  @override
  String get nationalityRequired => 'Nationality *';

  @override
  String get deleteDriverQ => 'Delete driver?';

  @override
  String get addDriverFile => 'Add driver file';

  @override
  String get serverFileName => 'Server file name';

  @override
  String get fileTypeIdRequired => 'File type id *';

  @override
  String get startDateYmd => 'Start yyyy-MM-dd';

  @override
  String get endDateYmd => 'End yyyy-MM-dd';

  @override
  String get actionAdd => 'Add';

  @override
  String addFailedWithMsg(Object msg) {
    return 'Add failed: $msg';
  }

  @override
  String get fileDescriptionOptionalAr => 'File description Arabic (optional)';

  @override
  String get fileDescriptionOptionalEn => 'File description English (optional)';

  @override
  String get required => 'Required';

  @override
  String get previewPdf => 'PDF preview';

  @override
  String get open => 'Open';

  @override
  String get pickAFileFirst => 'Please pick and upload a file first';

  @override
  String get savingDots => 'Saving…';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get all => 'all';

  @override
  String get sessionExpired => 'Session Expired, please Sign In Again';

  @override
  String get home => 'Home';

  @override
  String get browse => 'Browse';

  @override
  String get settings => 'Settings';

  @override
  String get errorLoadStatusDomain => 'Could not load status names.';

  @override
  String get errorInvalidRequestId => 'Invalid request id.';

  @override
  String get errorUnitHasNoDriverForNationality => 'At least one unit has no available drivers for its requested nationality.';

  @override
  String get errorUpdateFailedFlagFalse => 'Update failed (flag=false).';

  @override
  String get errorContractCreationFailed => 'Contract creation failed.';

  @override
  String get snackContractCreated => 'Contract created';

  @override
  String get labelVendor => 'Vendor';

  @override
  String get labelCustomer => 'Customer';

  @override
  String get labelIAmVendorQ => 'I am vendor?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get labelItem => 'Item';

  @override
  String get labelEquipmentId => 'Equipment ID';

  @override
  String get labelWeight => 'Weight';

  @override
  String get respFuel => 'Fuel';

  @override
  String get respDriverFood => 'Driver food';

  @override
  String get respDriverHousing => 'Driver housing';

  @override
  String get sectionStatusAcceptance => 'Status & Acceptance';

  @override
  String get flagVendorAccepted => 'Vendor accepted';

  @override
  String get flagCustomerAccepted => 'Customer accepted';

  @override
  String get sectionNotes => 'Notes';

  @override
  String get labelVendorNotes => 'Vendor notes';

  @override
  String get labelCustomerNotes => 'Customer notes';

  @override
  String get sectionAttachments => 'Attachments';

  @override
  String get sectionMeta => 'Meta';

  @override
  String get labelRequestId => 'Request ID';

  @override
  String get labelRequestNo => 'Request No.';

  @override
  String get labelCreatedAt => 'Created';

  @override
  String get labelUpdatedAt => 'Updated At';

  @override
  String fileType1(Object type) {
    return 'Type $type';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String driverWithId(Object id) {
    return 'Driver #$id';
  }

  @override
  String get superAdmin_title => 'Super Admin';

  @override
  String get superAdmin_tab_orgFiles => 'Org Files';

  @override
  String get superAdmin_tab_orgUsers => 'Org Users';

  @override
  String get superAdmin_tab_requestsOrders => 'Requests / Orders';

  @override
  String get superAdmin_tab_inactiveEquipments => 'Inactive Equipments';

  @override
  String get superAdmin_tab_inactiveOrgs => 'Inactive Organizations';

  @override
  String get superAdmin_gate_signIn_title => 'Sign in required';

  @override
  String get superAdmin_gate_signIn_message => 'This page is for Super Admin accounts.';

  @override
  String get superAdmin_gate_notAvailable_title => 'Not available';

  @override
  String get superAdmin_gate_notAvailable_message => 'Your account does not have Super Admin permission.';

  @override
  String get orgFiles_search_label => 'Search org files';

  @override
  String get orgFiles_delete_title => 'Delete file?';

  @override
  String orgFiles_delete_message(Object fileName) {
    return 'This will remove “$fileName”.';
  }

  @override
  String get orgFiles_empty => 'No organization files.';

  @override
  String get orgUsers_search_label => 'Search org users';

  @override
  String get orgUsers_remove_title => 'Remove org user?';

  @override
  String orgUsers_remove_message(Object orgId, Object userId) {
    return 'This will unlink user #$userId from organization #$orgId.';
  }

  @override
  String get orgUsers_empty => 'No organization users.';

  @override
  String get requests_search_label => 'Search requests / orders';

  @override
  String requests_item_title(Object id) {
    return 'Request #$id';
  }

  @override
  String get requests_empty => 'No requests found.';

  @override
  String get inactiveEquipments_search_label => 'Search inactive equipments';

  @override
  String get inactiveEquipments_empty => 'No inactive equipments.';

  @override
  String get inactiveOrgs_search_label => 'Search inactive organizations';

  @override
  String get inactiveOrgs_empty => 'No inactive organizations.';

  @override
  String get action_signIn => 'Sign in';

  @override
  String get action_back => 'Back';

  @override
  String get action_cancel => 'Cancel';

  @override
  String get action_delete => 'Delete';

  @override
  String get action_remove => 'Remove';

  @override
  String get action_previewOpen => 'Preview / Open';

  @override
  String get action_activate => 'Activate';

  @override
  String get action_deactivate => 'Deactivate';

  @override
  String get action_openOrganization => 'Open organization';

  @override
  String get action_removeFromOrg => 'Remove from org';

  @override
  String get common_signedIn => 'Signed in';

  @override
  String get common_updated => 'Updated';

  @override
  String get common_updateFailed => 'Update failed';

  @override
  String get common_deleted => 'Deleted';

  @override
  String get common_deleteFailed => 'Delete failed';

  @override
  String get common_removed => 'Removed';

  @override
  String get common_removeFailed => 'Remove failed';

  @override
  String get common_typeToSearch => 'Type to search';

  @override
  String common_orgNumber(Object id) {
    return 'Org #$id';
  }

  @override
  String get common_user => 'User';

  @override
  String get common_equipment => 'Equipment';

  @override
  String get common_organization => 'Organization';

  @override
  String get common_file => 'File';

  @override
  String get common_status => 'Status';

  @override
  String get common_active => 'Active';

  @override
  String get common_inactive => 'Inactive';

  @override
  String get common_expired => 'Expired';

  @override
  String get common_activated => 'Activated';

  @override
  String get common_deactivated => 'Deactivated';

  @override
  String get superAdmin_tab_overview => 'Overview';

  @override
  String get superAdmin_tab_settings => 'Settings';

  @override
  String get superAdmin_tab_auditLogs => 'Audit Logs';

  @override
  String get common_search => 'Search';

  @override
  String get overview_totalOrgs => 'Total organizations';

  @override
  String get overview_totalEquipments => 'Total equipments';

  @override
  String get overview_totalUsers => 'Total users';

  @override
  String get overview_openRequests => 'Open requests';

  @override
  String get overview_quick_createOrg => 'Create organization';

  @override
  String get overview_quick_inviteUser => 'Invite user';

  @override
  String get overview_quick_settings => 'Open settings';

  @override
  String get overview_recentActivity => 'Recent activity';

  @override
  String get settings_maintenanceMode => 'Maintenance mode';

  @override
  String get settings_maintenanceMode_desc => 'Temporarily disable the app for end users.';

  @override
  String get settings_allowSignups => 'Allow signups';

  @override
  String get settings_allowSignups_desc => 'Permit new users to register accounts.';

  @override
  String get settings_enableNotifications => 'Enable notifications';

  @override
  String get settings_enableNotifications_desc => 'Send system notifications to users.';

  @override
  String get settings_emptyOrError => 'Settings could not be loaded.';

  @override
  String get audit_search_label => 'Search audit logs';

  @override
  String get audit_empty => 'No audit logs found.';

  @override
  String get audit_filter_all => 'All';

  @override
  String get audit_filter_info => 'Info';

  @override
  String get audit_filter_warn => 'Warn';

  @override
  String get audit_filter_error => 'Error';

  @override
  String get search_hint => 'Type to search…';

  @override
  String get search_noResults => 'No results found.';

  @override
  String common_statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get common_organizations => 'Organizations';

  @override
  String get common_users => 'Users';

  @override
  String get common_equipments => 'Equipments';

  @override
  String get common_requests => 'Requests';

  @override
  String get action_save => 'Save';

  @override
  String get common_saved => 'Saved successfully.';

  @override
  String get common_saveFailed => 'Save failed.';

  @override
  String get action_close => 'Close';
}
