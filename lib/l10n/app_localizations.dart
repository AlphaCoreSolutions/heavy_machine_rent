import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HeavyRent'**
  String get appName;

  /// No description provided for @tooltipLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get tooltipLogin;

  /// No description provided for @tooltipLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tooltipLogout;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy gear, light work'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rent certified machines with drivers, on-demand.'**
  String get heroSubtitle;

  /// No description provided for @findEquipment.
  ///
  /// In en, this message translates to:
  /// **'Find equipment'**
  String get findEquipment;

  /// No description provided for @popularEquipment.
  ///
  /// In en, this message translates to:
  /// **'Popular equipment'**
  String get popularEquipment;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @couldNotLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Could not load equipment'**
  String get couldNotLoadEquipment;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noEquipmentYet.
  ///
  /// In en, this message translates to:
  /// **'No equipment yet.'**
  String get noEquipmentYet;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// Price line shown under equipment cards
  ///
  /// In en, this message translates to:
  /// **'From {price} / day'**
  String fromPerDay(String price);

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HeavyRent'**
  String get appTitle;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionRentNow.
  ///
  /// In en, this message translates to:
  /// **'Rent now'**
  String get actionRentNow;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get actionFilter;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search equipment, brands, cities...'**
  String get searchHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otp;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @withDriver.
  ///
  /// In en, this message translates to:
  /// **'With driver'**
  String get withDriver;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'{price} / day'**
  String pricePerDay(String price);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String validationRequired(String field);

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmail;

  /// No description provided for @msgOtpSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {phone}'**
  String msgOtpSent(String phone);

  /// No description provided for @snackSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get snackSaved;

  /// No description provided for @snackError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get snackError;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Heavy gear, light work'**
  String get homeHeadline;

  /// No description provided for @homeSub.
  ///
  /// In en, this message translates to:
  /// **'Rent certified machines on‑demand'**
  String get homeSub;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get filterBrand;

  /// No description provided for @filterCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCity;

  /// No description provided for @filterPriceDay.
  ///
  /// In en, this message translates to:
  /// **'Price/Day'**
  String get filterPriceDay;

  /// No description provided for @filterHasCerts.
  ///
  /// In en, this message translates to:
  /// **'Has certificates'**
  String get filterHasCerts;

  /// No description provided for @filterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance pricing'**
  String get filterDistance;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters or search keywords'**
  String get emptyBody;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @testNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification'**
  String get testNotificationMessage;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @inAppBanners.
  ///
  /// In en, this message translates to:
  /// **'In-app banners'**
  String get inAppBanners;

  /// No description provided for @emailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Email updates'**
  String get emailUpdates;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

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

  /// No description provided for @quietHoursHint.
  ///
  /// In en, this message translates to:
  /// **'During quiet hours, sounds are muted. (Demo—wire to your push provider later.)'**
  String get quietHoursHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @notAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailableTitle;

  /// No description provided for @signInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequiredTitle;

  /// No description provided for @restrictedPageMessage.
  ///
  /// In en, this message translates to:
  /// **'This page is only available for accounts with user type #17 or #20.'**
  String get restrictedPageMessage;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get signInPrompt;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get statusIncomplete;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign in again anytime.'**
  String get logoutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @completeYourAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your account to unlock Organization and My equipment.'**
  String get completeYourAccountBody;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAction;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @manageSection.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageSection;

  /// No description provided for @activitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activitySection;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal & company details'**
  String get profileSubtitle;

  /// No description provided for @appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, notifications'**
  String get appSettingsSubtitle;

  /// No description provided for @organizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationTitle;

  /// No description provided for @organizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Company info & compliance'**
  String get organizationSubtitle;

  /// No description provided for @myEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'My equipment'**
  String get myEquipmentTitle;

  /// No description provided for @myEquipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your fleet'**
  String get myEquipmentSubtitle;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @requestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your requests'**
  String get requestsSubtitle;

  /// No description provided for @superAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdminTitle;

  /// No description provided for @superAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open super admin panel (debug)'**
  String get superAdminSubtitle;

  /// No description provided for @contractsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contractsTitle;

  /// No description provided for @contractsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending, open, finished, closed'**
  String get contractsSubtitle;

  /// No description provided for @ordersHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders (history)'**
  String get ordersHistoryTitle;

  /// No description provided for @ordersHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past orders & receipts'**
  String get ordersHistorySubtitle;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'966'**
  String get codeHint;

  /// No description provided for @mobile9DigitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile (9 digits)'**
  String get mobile9DigitsLabel;

  /// No description provided for @mobile9DigitsHint.
  ///
  /// In en, this message translates to:
  /// **'5XX XXX XXX'**
  String get mobile9DigitsHint;

  /// No description provided for @enterNineDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter 9 digits'**
  String get enterNineDigits;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @devOtpHint.
  ///
  /// In en, this message translates to:
  /// **'DEV OTP: {code}'**
  String devOtpHint(String code);

  /// No description provided for @enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCodeTitle;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get verifyAndContinue;

  /// No description provided for @didntGetItTapResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Tap \"Resend code\".'**
  String get didntGetItTapResend;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInWithMobileBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number.\nFast, secure, OTP-based login.'**
  String get signInWithMobileBlurb;

  /// No description provided for @neverShareNumber.
  ///
  /// In en, this message translates to:
  /// **'We’ll never share your number.'**
  String get neverShareNumber;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent'**
  String get otpSent;

  /// No description provided for @couldNotStartVerification.
  ///
  /// In en, this message translates to:
  /// **'Could not start verification'**
  String get couldNotStartVerification;

  /// No description provided for @enterFourDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code'**
  String get enterFourDigitCode;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get invalidOrExpiredCode;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @passwordKeep.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordKeep;

  /// No description provided for @validationMinChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum {min} characters'**
  String validationMinChars(int min);

  /// No description provided for @actionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get actionSaveChanges;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @profileCompletePrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileCompletePrompt;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @couldNotSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile'**
  String get couldNotSaveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @orgTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get orgTitle;

  /// No description provided for @orgCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create organization'**
  String get orgCreateTitle;

  /// No description provided for @orgType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get orgType;

  /// No description provided for @orgStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orgStatus;

  /// No description provided for @orgNameArabic.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get orgNameArabic;

  /// No description provided for @orgNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get orgNameEnglish;

  /// No description provided for @orgBriefArabic.
  ///
  /// In en, this message translates to:
  /// **'Brief (Arabic)'**
  String get orgBriefArabic;

  /// No description provided for @orgBriefEnglish.
  ///
  /// In en, this message translates to:
  /// **'Brief (English)'**
  String get orgBriefEnglish;

  /// No description provided for @orgCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get orgCountry;

  /// No description provided for @orgCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get orgCity;

  /// No description provided for @orgAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orgAddress;

  /// No description provided for @orgCrNumber.
  ///
  /// In en, this message translates to:
  /// **'C.R. Number'**
  String get orgCrNumber;

  /// No description provided for @orgVatNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT Number'**
  String get orgVatNumber;

  /// No description provided for @orgMainMobile.
  ///
  /// In en, this message translates to:
  /// **'Main mobile'**
  String get orgMainMobile;

  /// No description provided for @orgSecondMobile.
  ///
  /// In en, this message translates to:
  /// **'Second mobile'**
  String get orgSecondMobile;

  /// No description provided for @orgMainEmail.
  ///
  /// In en, this message translates to:
  /// **'Main email'**
  String get orgMainEmail;

  /// No description provided for @orgSecondEmail.
  ///
  /// In en, this message translates to:
  /// **'Second email'**
  String get orgSecondEmail;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get edit;

  /// No description provided for @orgFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files • Attachments'**
  String get orgFilesTitle;

  /// No description provided for @orgAddFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get orgAddFile;

  /// No description provided for @orgCreateToManageFiles.
  ///
  /// In en, this message translates to:
  /// **'Create organization to manage files.'**
  String get orgCreateToManageFiles;

  /// No description provided for @orgNoFilesYet.
  ///
  /// In en, this message translates to:
  /// **'No files yet.'**
  String get orgNoFilesYet;

  /// No description provided for @attachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachmentTitle;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'File type'**
  String get fileType;

  /// No description provided for @addFileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Add file name *'**
  String get addFileNameRequired;

  /// No description provided for @pickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick file *'**
  String get pickFile;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get issueDate;

  /// No description provided for @expireDate.
  ///
  /// In en, this message translates to:
  /// **'Expire date'**
  String get expireDate;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @orgEnterNameMin3.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name (≥ 3 chars)'**
  String get orgEnterNameMin3;

  /// No description provided for @orgChooseTypeStatusCity.
  ///
  /// In en, this message translates to:
  /// **'Please choose Status, Type and City'**
  String get orgChooseTypeStatusCity;

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get createFailed;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @orgCreated.
  ///
  /// In en, this message translates to:
  /// **'Organization created'**
  String get orgCreated;

  /// No description provided for @orgUpdated.
  ///
  /// In en, this message translates to:
  /// **'Organization updated'**
  String get orgUpdated;

  /// No description provided for @orgCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save organization'**
  String get orgCouldNotSave;

  /// No description provided for @failedToLoadOrganization.
  ///
  /// In en, this message translates to:
  /// **'Failed to load organization'**
  String get failedToLoadOrganization;

  /// No description provided for @orgCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create organization first'**
  String get orgCreateFirst;

  /// No description provided for @chooseFileType.
  ///
  /// In en, this message translates to:
  /// **'Choose a file type'**
  String get chooseFileType;

  /// No description provided for @pickFileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a file — name is required'**
  String get pickFileNameRequired;

  /// No description provided for @fileAdded.
  ///
  /// In en, this message translates to:
  /// **'File added'**
  String get fileAdded;

  /// No description provided for @fileUpdated.
  ///
  /// In en, this message translates to:
  /// **'File updated'**
  String get fileUpdated;

  /// No description provided for @couldNotSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Could not save file'**
  String get couldNotSaveFile;

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFileTitle;

  /// No description provided for @deleteFileBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get deleteFileBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteMissingId.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: missing file id'**
  String get deleteMissingId;

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get fileDeleted;

  /// No description provided for @couldNotDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Could not delete file'**
  String get couldNotDeleteFile;

  /// No description provided for @myEquipSignInBody.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to manage your equipment.'**
  String get myEquipSignInBody;

  /// No description provided for @orgNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization needed'**
  String get orgNeededTitle;

  /// No description provided for @orgNeededBody.
  ///
  /// In en, this message translates to:
  /// **'Add your organization before listing or managing equipment.'**
  String get orgNeededBody;

  /// No description provided for @actionAddOrganization.
  ///
  /// In en, this message translates to:
  /// **'Add organization'**
  String get actionAddOrganization;

  /// No description provided for @submittedMayTakeMoment.
  ///
  /// In en, this message translates to:
  /// **'Submitted. It may take a moment to appear.'**
  String get submittedMayTakeMoment;

  /// No description provided for @cantAddEquipment.
  ///
  /// In en, this message translates to:
  /// **'Can’t add equipment'**
  String get cantAddEquipment;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @unexpectedErrorWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {msg}'**
  String unexpectedErrorWithMsg(String msg);

  /// No description provided for @actionAddEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add equipment'**
  String get actionAddEquipment;

  /// No description provided for @failedToLoadYourEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your equipment.\n{error}'**
  String failedToLoadYourEquipment(String error);

  /// No description provided for @noEquipmentYetTapAdd.
  ///
  /// In en, this message translates to:
  /// **'No equipment yet. Tap “Add equipment” to create one.'**
  String get noEquipmentYetTapAdd;

  /// No description provided for @openAsCustomerToRent.
  ///
  /// In en, this message translates to:
  /// **'Open as customer to rent'**
  String get openAsCustomerToRent;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequired;

  /// No description provided for @equipSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment settings'**
  String get equipSettingsTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get tabImages;

  /// No description provided for @tabTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get tabTerms;

  /// No description provided for @tabDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get tabDrivers;

  /// No description provided for @tabCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get tabCertificates;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get basicInfo;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (EN)'**
  String get nameEn;

  /// No description provided for @nameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (AR)'**
  String get nameAr;

  /// No description provided for @exampleExcavator.
  ///
  /// In en, this message translates to:
  /// **'e.g. Excavator 22T'**
  String get exampleExcavator;

  /// No description provided for @exampleExcavatorAr.
  ///
  /// In en, this message translates to:
  /// **'e.g. حفار ٢٢ طن'**
  String get exampleExcavatorAr;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @pricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Price / hour'**
  String get pricePerHour;

  /// No description provided for @downPaymentPct.
  ///
  /// In en, this message translates to:
  /// **'Down payment: {pct}% → {amount}'**
  String downPaymentPct(Object pct, Object amount);

  /// No description provided for @quantityAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Quantity & Status'**
  String get quantityAndStatus;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @equipmentWeight.
  ///
  /// In en, this message translates to:
  /// **'Equipment weight'**
  String get equipmentWeight;

  /// No description provided for @activeVisible.
  ///
  /// In en, this message translates to:
  /// **'Active (visible)'**
  String get activeVisible;

  /// No description provided for @inactiveHidden.
  ///
  /// In en, this message translates to:
  /// **'Inactive (hidden)'**
  String get inactiveHidden;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @noteSendsFullObject.
  ///
  /// In en, this message translates to:
  /// **'Note: saving sends a full object (IDs only for domains) to PUT /Equipment/update.'**
  String get noteSendsFullObject;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {msg}'**
  String saveFailedWithMsg(Object msg);

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @actionAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get actionAddImage;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @noImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No images yet.'**
  String get noImagesYet;

  /// No description provided for @imageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get imageUploaded;

  /// No description provided for @uploadFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {msg}'**
  String uploadFailedWithMsg(Object msg);

  /// No description provided for @imageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get imageDeleted;

  /// No description provided for @deleteFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {msg}'**
  String deleteFailedWithMsg(Object msg);

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAddTerm.
  ///
  /// In en, this message translates to:
  /// **'Add term'**
  String get actionAddTerm;

  /// No description provided for @actionSaveOrder.
  ///
  /// In en, this message translates to:
  /// **'Save order'**
  String get actionSaveOrder;

  /// No description provided for @noTermsYetCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'No terms yet. Click “Add term” to create your first item.'**
  String get noTermsYetCreateFirst;

  /// No description provided for @addTerm.
  ///
  /// In en, this message translates to:
  /// **'Add term'**
  String get addTerm;

  /// No description provided for @editTerm.
  ///
  /// In en, this message translates to:
  /// **'Edit term'**
  String get editTerm;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @orderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order saved'**
  String get orderSaved;

  /// No description provided for @orderSaveFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Order save failed: {msg}'**
  String orderSaveFailedWithMsg(Object msg);

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @nationalityIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationality id:'**
  String get nationalityIdLabel;

  /// No description provided for @actionAddDriver.
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get actionAddDriver;

  /// No description provided for @noDriversYet.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet.'**
  String get noDriversYet;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @actionAddFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get actionAddFile;

  /// No description provided for @deleteFileQ.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get deleteFileQ;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @fileAndTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'File and Type ID are required'**
  String get fileAndTypeRequired;

  /// No description provided for @actionAddCertificate.
  ///
  /// In en, this message translates to:
  /// **'Add certificate'**
  String get actionAddCertificate;

  /// No description provided for @noCertificatesYet.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet.'**
  String get noCertificatesYet;

  /// No description provided for @addCertificate.
  ///
  /// In en, this message translates to:
  /// **'Add certificate'**
  String get addCertificate;

  /// No description provided for @editCertificate.
  ///
  /// In en, this message translates to:
  /// **'Edit certificate'**
  String get editCertificate;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @pdfSelected.
  ///
  /// In en, this message translates to:
  /// **'PDF selected'**
  String get pdfSelected;

  /// No description provided for @nameEnReq.
  ///
  /// In en, this message translates to:
  /// **'Name (EN) *'**
  String get nameEnReq;

  /// No description provided for @nameArReq.
  ///
  /// In en, this message translates to:
  /// **'Name (AR) *'**
  String get nameArReq;

  /// No description provided for @typeDomain10Req.
  ///
  /// In en, this message translates to:
  /// **'Type*'**
  String get typeDomain10Req;

  /// No description provided for @issueDateReq.
  ///
  /// In en, this message translates to:
  /// **'Issue date *'**
  String get issueDateReq;

  /// No description provided for @expireDateReq.
  ///
  /// In en, this message translates to:
  /// **'Expire date *'**
  String get expireDateReq;

  /// No description provided for @isImage.
  ///
  /// In en, this message translates to:
  /// **'Is image'**
  String get isImage;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @pleasePickIssueAndExpire.
  ///
  /// In en, this message translates to:
  /// **'Please pick both Issue and Expire dates.'**
  String get pleasePickIssueAndExpire;

  /// No description provided for @pleaseChooseType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a Type.'**
  String get pleaseChooseType;

  /// No description provided for @pleaseChooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Please choose a document file.'**
  String get pleaseChooseDocument;

  /// No description provided for @deleteCertificateQ.
  ///
  /// In en, this message translates to:
  /// **'Delete certificate?'**
  String get deleteCertificateQ;

  /// No description provided for @noPastOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No past orders yet'**
  String get noPastOrdersYet;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failedToLoadOrders;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequestsTitle;

  /// No description provided for @signInToViewRequests.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your requests'**
  String get signInToViewRequests;

  /// No description provided for @signInToViewRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to see your request history and details.'**
  String get signInToViewRequestsBody;

  /// No description provided for @failedToLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Failed to load requests'**
  String get failedToLoadRequests;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get noRequestsYet;

  /// No description provided for @requestNumber.
  ///
  /// In en, this message translates to:
  /// **'Request #'**
  String get requestNumber;

  /// No description provided for @asVendor.
  ///
  /// In en, this message translates to:
  /// **'As Vendor'**
  String get asVendor;

  /// No description provided for @asCustomer.
  ///
  /// In en, this message translates to:
  /// **'As Customer'**
  String get asCustomer;

  /// No description provided for @daysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysSuffix;

  /// No description provided for @requestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get requestDetailsTitle;

  /// No description provided for @failedToLoadRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to load request'**
  String get failedToLoadRequest;

  /// No description provided for @sectionDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sectionDuration;

  /// No description provided for @sectionPriceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get sectionPriceBreakdown;

  /// No description provided for @priceBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get priceBase;

  /// No description provided for @priceDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get priceDistance;

  /// No description provided for @priceVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get priceVat;

  /// No description provided for @priceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get priceTotal;

  /// No description provided for @priceDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get priceDownPayment;

  /// No description provided for @sectionAssignDrivers.
  ///
  /// In en, this message translates to:
  /// **'Assign drivers'**
  String get sectionAssignDrivers;

  /// No description provided for @errorLoadDriverLocations.
  ///
  /// In en, this message translates to:
  /// **'Could not load driver locations.'**
  String get errorLoadDriverLocations;

  /// No description provided for @emptyNoDriverLocations.
  ///
  /// In en, this message translates to:
  /// **'No driver locations for this request.'**
  String get emptyNoDriverLocations;

  /// No description provided for @errorNoDriversForNationality.
  ///
  /// In en, this message translates to:
  /// **'Some units have no available drivers for the requested nationality.'**
  String get errorNoDriversForNationality;

  /// No description provided for @errorAssignDriverEachUnit.
  ///
  /// In en, this message translates to:
  /// **'Select a driver for every unit.'**
  String get errorAssignDriverEachUnit;

  /// No description provided for @actionCreateContract.
  ///
  /// In en, this message translates to:
  /// **'Create contract'**
  String get actionCreateContract;

  /// No description provided for @creatingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingEllipsis;

  /// No description provided for @actionCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get actionCancelRequest;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @requestedNationality.
  ///
  /// In en, this message translates to:
  /// **'Requested nationality'**
  String get requestedNationality;

  /// No description provided for @dropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropoffLabel;

  /// No description provided for @coordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coords'**
  String get coordinatesLabel;

  /// No description provided for @emptyNoDriversForThisNationality.
  ///
  /// In en, this message translates to:
  /// **'No drivers available for this nationality.'**
  String get emptyNoDriversForThisNationality;

  /// No description provided for @labelAssignDriverFiltered.
  ///
  /// In en, this message translates to:
  /// **'Assign driver (filtered by nationality)'**
  String get labelAssignDriverFiltered;

  /// No description provided for @hintSelectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select driver'**
  String get hintSelectDriver;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// No description provided for @requestListLeadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Request #'**
  String get requestListLeadingLabel;

  /// No description provided for @currencySar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySar;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @daySingular.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get daySingular;

  /// No description provided for @toDateSep.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get toDateSep;

  /// No description provided for @detailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Details copied'**
  String get detailsCopied;

  /// No description provided for @requestSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmittedTitle;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get successTitle;

  /// No description provided for @numberPendingChip.
  ///
  /// In en, this message translates to:
  /// **'Number pending'**
  String get numberPendingChip;

  /// No description provided for @requestSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your request has been submitted.'**
  String get requestSubmittedBody;

  /// No description provided for @requestLabel.
  ///
  /// In en, this message translates to:
  /// **'Request:'**
  String get requestLabel;

  /// No description provided for @requestHashPrefix.
  ///
  /// In en, this message translates to:
  /// **'Request #'**
  String get requestHashPrefix;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRangeLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @actionCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get actionCopyDetails;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Pluralized day label used when needed
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# day} other {# days}}'**
  String daysCount(num count);

  /// No description provided for @equipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipmentTitle;

  /// No description provided for @searchByDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Search by description…'**
  String get searchByDescriptionHint;

  /// No description provided for @failedToLoadEquipmentList.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipment list'**
  String get failedToLoadEquipmentList;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @equipEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New equipment'**
  String get equipEditorTitleNew;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @errorCouldNotLoadFactories.
  ///
  /// In en, this message translates to:
  /// **'Could not load factories'**
  String get errorCouldNotLoadFactories;

  /// No description provided for @errorChooseEquipmentType.
  ///
  /// In en, this message translates to:
  /// **'Choose an equipment type'**
  String get errorChooseEquipmentType;

  /// No description provided for @errorChooseFactory.
  ///
  /// In en, this message translates to:
  /// **'Choose a factory'**
  String get errorChooseFactory;

  /// No description provided for @errorEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter a description (EN or AR)'**
  String get errorEnterDescription;

  /// No description provided for @errorFailedToLoadOptions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load options'**
  String get errorFailedToLoadOptions;

  /// No description provided for @sectionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sectionType;

  /// No description provided for @labelEquipmentList.
  ///
  /// In en, this message translates to:
  /// **'Equipment list'**
  String get labelEquipmentList;

  /// No description provided for @selectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Selected:'**
  String get selectedPrefix;

  /// No description provided for @sectionOwnershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Ownership & Status'**
  String get sectionOwnershipStatus;

  /// No description provided for @labelFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get labelFactory;

  /// No description provided for @hintSelectFactory.
  ///
  /// In en, this message translates to:
  /// **'Select a factory'**
  String get hintSelectFactory;

  /// No description provided for @tooltipRefreshFactories.
  ///
  /// In en, this message translates to:
  /// **'Refresh factories'**
  String get tooltipRefreshFactories;

  /// No description provided for @labelStatusD11.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatusD11;

  /// No description provided for @sectionLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get sectionLogistics;

  /// No description provided for @labelCategoryD9.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategoryD9;

  /// No description provided for @labelFuelRespD7.
  ///
  /// In en, this message translates to:
  /// **'Fuel responsibility'**
  String get labelFuelRespD7;

  /// No description provided for @labelTransferTypeD8.
  ///
  /// In en, this message translates to:
  /// **'Transfer type'**
  String get labelTransferTypeD8;

  /// No description provided for @labelTransferRespD7.
  ///
  /// In en, this message translates to:
  /// **'Transfer responsibility'**
  String get labelTransferRespD7;

  /// No description provided for @sectionDriverRespD7.
  ///
  /// In en, this message translates to:
  /// **'Driver responsibilities'**
  String get sectionDriverRespD7;

  /// No description provided for @labelTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get labelTransport;

  /// No description provided for @labelFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get labelFood;

  /// No description provided for @labelHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get labelHousing;

  /// No description provided for @sectionDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Descriptions'**
  String get sectionDescriptions;

  /// No description provided for @labelDescEnglish.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get labelDescEnglish;

  /// No description provided for @hintDescEnglish.
  ///
  /// In en, this message translates to:
  /// **'e.g. Excavator 22T'**
  String get hintDescEnglish;

  /// No description provided for @labelDescArabic.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get labelDescArabic;

  /// No description provided for @hintDescArabic.
  ///
  /// In en, this message translates to:
  /// **'e.g. 22T Excavator (Arabic)'**
  String get hintDescArabic;

  /// No description provided for @sectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get sectionPricing;

  /// No description provided for @labelPricePerDay.
  ///
  /// In en, this message translates to:
  /// **'Price per day'**
  String get labelPricePerDay;

  /// No description provided for @hintPricePerDay.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1600'**
  String get hintPricePerDay;

  /// No description provided for @labelPricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get labelPricePerHour;

  /// No description provided for @hintPricePerHour.
  ///
  /// In en, this message translates to:
  /// **'e.g. 160'**
  String get hintPricePerHour;

  /// No description provided for @ruleHoursPerDayAndDp.
  ///
  /// In en, this message translates to:
  /// **'Rule: 1 day = {hours} hours. Down payment = {percent}%.'**
  String ruleHoursPerDayAndDp(Object hours, Object percent);

  /// No description provided for @downPaymentAuto.
  ///
  /// In en, this message translates to:
  /// **'Down payment (auto): {amount}'**
  String downPaymentAuto(Object amount);

  /// No description provided for @sectionQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get sectionQuantity;

  /// No description provided for @labelQuantityAlsoAvailable.
  ///
  /// In en, this message translates to:
  /// **'Quantity (also used as Available)'**
  String get labelQuantityAlsoAvailable;

  /// No description provided for @hintQuantity.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1'**
  String get hintQuantity;

  /// No description provided for @noteAvailableReserved.
  ///
  /// In en, this message translates to:
  /// **'Available = Quantity, Reserved starts at 0 (both updated later).'**
  String get noteAvailableReserved;

  /// No description provided for @unnamedFactory.
  ///
  /// In en, this message translates to:
  /// **'Unnamed factory'**
  String get unnamedFactory;

  /// No description provided for @contractTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractTitle;

  /// No description provided for @actionOpenContractSheet.
  ///
  /// In en, this message translates to:
  /// **'Open Contract Sheet'**
  String get actionOpenContractSheet;

  /// No description provided for @actionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// No description provided for @printingStubMessage.
  ///
  /// In en, this message translates to:
  /// **'Printing stub — wire up printing/pdf here.'**
  String get printingStubMessage;

  /// No description provided for @errorFailedToLoadContractDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contract details'**
  String get errorFailedToLoadContractDetails;

  /// No description provided for @errorNoContractSlice.
  ///
  /// In en, this message translates to:
  /// **'No contract slice found/created.'**
  String get errorNoContractSlice;

  /// No description provided for @rentalAgreementHeader.
  ///
  /// In en, this message translates to:
  /// **'RENTAL AGREEMENT'**
  String get rentalAgreementHeader;

  /// No description provided for @contractNumber.
  ///
  /// In en, this message translates to:
  /// **'Contract #{num}'**
  String contractNumber(Object num);

  /// No description provided for @sectionParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get sectionParties;

  /// No description provided for @sectionRequestSummary.
  ///
  /// In en, this message translates to:
  /// **'Request Summary'**
  String get sectionRequestSummary;

  /// No description provided for @sectionEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get sectionEquipment;

  /// No description provided for @sectionResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities'**
  String get sectionResponsibilities;

  /// No description provided for @sectionTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get sectionTerms;

  /// No description provided for @sectionDriverAssignments.
  ///
  /// In en, this message translates to:
  /// **'Driver Assignments (per requested unit)'**
  String get sectionDriverAssignments;

  /// No description provided for @sectionSignatures.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get sectionSignatures;

  /// No description provided for @vendorLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorLabel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @requestNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Request No.'**
  String get requestNumberLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// No description provided for @rentPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Rent / Day'**
  String get rentPerDayLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabel;

  /// No description provided for @downPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get downPaymentLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @fuelResponsibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Responsibility'**
  String get fuelResponsibilityLabel;

  /// No description provided for @driverFoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Food'**
  String get driverFoodLabel;

  /// No description provided for @driverHousingLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Housing'**
  String get driverHousingLabel;

  /// No description provided for @driverTransportLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Transport'**
  String get driverTransportLabel;

  /// No description provided for @responsibilityValue.
  ///
  /// In en, this message translates to:
  /// **'{label} (ID #{id})'**
  String responsibilityValue(Object label, Object id);

  /// No description provided for @termDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment before mobilization; remaining as per agreed schedule.'**
  String get termDownPayment;

  /// No description provided for @termManufacturerGuidelines.
  ///
  /// In en, this message translates to:
  /// **'All equipment to be used according to manufacturer guidelines.'**
  String get termManufacturerGuidelines;

  /// No description provided for @termCustomerSiteAccess.
  ///
  /// In en, this message translates to:
  /// **'Customer is responsible for site access and safe working environment.'**
  String get termCustomerSiteAccess;

  /// No description provided for @termLiability.
  ///
  /// In en, this message translates to:
  /// **'Damages and liability per company terms and applicable law.'**
  String get termLiability;

  /// No description provided for @equipmentTermsHeading.
  ///
  /// In en, this message translates to:
  /// **'Equipment Terms:'**
  String get equipmentTermsHeading;

  /// No description provided for @noDriverLocations.
  ///
  /// In en, this message translates to:
  /// **'No driver locations found for this request.'**
  String get noDriverLocations;

  /// No description provided for @requestedNationalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested nationality'**
  String get requestedNationalityLabel;

  /// No description provided for @coordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Coords'**
  String get coordsLabel;

  /// No description provided for @assignedDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get assignedDriverLabel;

  /// No description provided for @companyLogo.
  ///
  /// In en, this message translates to:
  /// **'VISION CIT'**
  String get companyLogo;

  /// No description provided for @detailHash.
  ///
  /// In en, this message translates to:
  /// **'Detail #{id}'**
  String detailHash(Object id);

  /// No description provided for @contractSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract Sheet'**
  String get contractSheetTitle;

  /// No description provided for @contractChip.
  ///
  /// In en, this message translates to:
  /// **'Contract #{id}'**
  String contractChip(Object id);

  /// No description provided for @requestChip.
  ///
  /// In en, this message translates to:
  /// **'Req #{id}'**
  String requestChip(Object id);

  /// No description provided for @qtyChip.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qtyChip(int qty);

  /// No description provided for @dateRangeChip.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String dateRangeChip(Object from, Object to);

  /// No description provided for @roleVendor.
  ///
  /// In en, this message translates to:
  /// **'Role: Vendor'**
  String get roleVendor;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Role: Customer'**
  String get roleCustomer;

  /// No description provided for @rowNothingToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save for this row.'**
  String get rowNothingToSave;

  /// No description provided for @rowLabel.
  ///
  /// In en, this message translates to:
  /// **'u{unit} {date}'**
  String rowLabel(Object unit, Object date);

  /// No description provided for @rowSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved ({label}).'**
  String rowSaved(Object label);

  /// No description provided for @rowSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed ({label}).'**
  String rowSaveFailed(Object label);

  /// No description provided for @endpoint405Noop.
  ///
  /// In en, this message translates to:
  /// **'Update endpoint not enabled (405). Nothing changed on the server.'**
  String get endpoint405Noop;

  /// No description provided for @savedChip.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedChip;

  /// No description provided for @unsavedChip.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsavedChip;

  /// No description provided for @plannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get plannedLabel;

  /// No description provided for @actualLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actualLabel;

  /// No description provided for @overtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtimeLabel;

  /// No description provided for @customerNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer note'**
  String get customerNoteLabel;

  /// No description provided for @vendorNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor note'**
  String get vendorNoteLabel;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingEllipsis;

  /// No description provided for @infoCreateActivateOrg.
  ///
  /// In en, this message translates to:
  /// **'Please create/activate your Organization first.'**
  String get infoCreateActivateOrg;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet.'**
  String get noContractsYet;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get searchChats;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet.'**
  String get noChatsYet;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat #{id}'**
  String chatTitle(Object id);

  /// No description provided for @threadActionsSoon.
  ///
  /// In en, this message translates to:
  /// **'Thread actions coming soon'**
  String get threadActionsSoon;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @sendingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingEllipsis;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String timeMinutesShort(Object m);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String timeHoursShort(Object h);

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{d}d'**
  String timeDaysShort(Object d);

  /// No description provided for @title_equipmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Equipment details'**
  String get title_equipmentDetails;

  /// No description provided for @msg_failedLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipment'**
  String get msg_failedLoadEquipment;

  /// No description provided for @label_availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get label_availability;

  /// No description provided for @label_rentFrom.
  ///
  /// In en, this message translates to:
  /// **'Rent Date (From)'**
  String get label_rentFrom;

  /// No description provided for @hint_yyyyMMdd.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get hint_yyyyMMdd;

  /// No description provided for @label_returnTo.
  ///
  /// In en, this message translates to:
  /// **'Return Date (To)'**
  String get label_returnTo;

  /// No description provided for @pill_days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String pill_days(num count);

  /// No description provided for @label_expectedKm.
  ///
  /// In en, this message translates to:
  /// **'Expected distance (km)'**
  String get label_expectedKm;

  /// No description provided for @mini_pricePerKm.
  ///
  /// In en, this message translates to:
  /// **'{currency} {price} / km'**
  String mini_pricePerKm(Object currency, Object price);

  /// No description provided for @label_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get label_quantity;

  /// No description provided for @label_requestedQty.
  ///
  /// In en, this message translates to:
  /// **'Requested quantity'**
  String get label_requestedQty;

  /// No description provided for @mini_available.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String mini_available(Object count);

  /// No description provided for @label_driverLocations.
  ///
  /// In en, this message translates to:
  /// **'Driver Locations'**
  String get label_driverLocations;

  /// No description provided for @msg_loadingNats.
  ///
  /// In en, this message translates to:
  /// **'Loading available driver nationalities…'**
  String get msg_loadingNats;

  /// No description provided for @msg_noNats.
  ///
  /// In en, this message translates to:
  /// **'No driver nationalities available for this equipment.'**
  String get msg_noNats;

  /// No description provided for @label_driverNationality.
  ///
  /// In en, this message translates to:
  /// **'Driver nationality *'**
  String get label_driverNationality;

  /// No description provided for @label_dropoffAddress.
  ///
  /// In en, this message translates to:
  /// **'Drop-off address'**
  String get label_dropoffAddress;

  /// No description provided for @label_dropoffLat.
  ///
  /// In en, this message translates to:
  /// **'Drop-off latitude *'**
  String get label_dropoffLat;

  /// No description provided for @label_dropoffLon.
  ///
  /// In en, this message translates to:
  /// **'Drop-off longitude *'**
  String get label_dropoffLon;

  /// No description provided for @label_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get label_notes;

  /// No description provided for @chip_available.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String chip_available(Object count);

  /// No description provided for @label_priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get label_priceBreakdown;

  /// No description provided for @row_perUnit.
  ///
  /// In en, this message translates to:
  /// **'Per unit'**
  String get row_perUnit;

  /// No description provided for @row_base.
  ///
  /// In en, this message translates to:
  /// **'Base ({price} × {days} day)'**
  String row_base(Object days, Object price);

  /// No description provided for @row_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance ({pricePerKm} × {km} km)'**
  String row_distance(Object km, Object pricePerKm);

  /// No description provided for @row_vat.
  ///
  /// In en, this message translates to:
  /// **'VAT {rate}%'**
  String row_vat(Object rate);

  /// No description provided for @row_perUnitTotal.
  ///
  /// In en, this message translates to:
  /// **'Per-unit total'**
  String get row_perUnitTotal;

  /// No description provided for @row_qtyTimes.
  ///
  /// In en, this message translates to:
  /// **'× Quantity ({qty})'**
  String row_qtyTimes(Object qty);

  /// No description provided for @row_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get row_subtotal;

  /// No description provided for @row_vatOnly.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get row_vatOnly;

  /// No description provided for @row_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get row_total;

  /// No description provided for @row_downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get row_downPayment;

  /// No description provided for @btn_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get btn_submit;

  /// No description provided for @btn_submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get btn_submitting;

  /// No description provided for @row_fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {value}'**
  String row_fuel(Object value);

  /// No description provided for @err_chooseDates.
  ///
  /// In en, this message translates to:
  /// **'Please choose dates'**
  String get err_chooseDates;

  /// No description provided for @info_signInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get info_signInFirst;

  /// No description provided for @err_qtyMin.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1'**
  String get err_qtyMin;

  /// No description provided for @err_qtyAvail.
  ///
  /// In en, this message translates to:
  /// **'Only {count} piece(s) available'**
  String err_qtyAvail(Object count);

  /// No description provided for @err_unitSelectNat.
  ///
  /// In en, this message translates to:
  /// **'Unit {index}: Select a nationality'**
  String err_unitSelectNat(Object index);

  /// No description provided for @err_unitLatLng.
  ///
  /// In en, this message translates to:
  /// **'Unit {index}: Drop-off lat/long required'**
  String err_unitLatLng(Object index);

  /// No description provided for @err_vendorMissing.
  ///
  /// In en, this message translates to:
  /// **'Vendor not found for this equipment.'**
  String get err_vendorMissing;

  /// No description provided for @info_createOrg.
  ///
  /// In en, this message translates to:
  /// **'Please create/activate your Organization first.'**
  String get info_createOrg;

  /// No description provided for @err_loadNats.
  ///
  /// In en, this message translates to:
  /// **'Could not load equipment driver nationalities.'**
  String get err_loadNats;

  /// No description provided for @err_loadResp.
  ///
  /// In en, this message translates to:
  /// **'Could not load responsibility names.'**
  String get err_loadResp;

  /// No description provided for @equipDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment details'**
  String get equipDetailsTitle;

  /// No description provided for @msgFailedLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipment'**
  String get msgFailedLoadEquipment;

  /// No description provided for @labelAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get labelAvailability;

  /// No description provided for @labelRentFrom.
  ///
  /// In en, this message translates to:
  /// **'Rent Date (From)'**
  String get labelRentFrom;

  /// No description provided for @hintYyyyMmDd.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get hintYyyyMmDd;

  /// No description provided for @labelReturnTo.
  ///
  /// In en, this message translates to:
  /// **'Return Date (To)'**
  String get labelReturnTo;

  /// No description provided for @pillDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String pillDays(int count);

  /// No description provided for @labelExpectedKm.
  ///
  /// In en, this message translates to:
  /// **'Expected distance (km)'**
  String get labelExpectedKm;

  /// No description provided for @miniPricePerKm.
  ///
  /// In en, this message translates to:
  /// **'{currency} {price} / km'**
  String miniPricePerKm(String currency, String price);

  /// No description provided for @labelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get labelQuantity;

  /// No description provided for @labelRequestedQty.
  ///
  /// In en, this message translates to:
  /// **'Requested quantity'**
  String get labelRequestedQty;

  /// No description provided for @miniAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String miniAvailable(int count);

  /// No description provided for @labelDriverLocations.
  ///
  /// In en, this message translates to:
  /// **'Driver Locations'**
  String get labelDriverLocations;

  /// No description provided for @msgLoadingNats.
  ///
  /// In en, this message translates to:
  /// **'Loading available driver nationalities…'**
  String get msgLoadingNats;

  /// No description provided for @msgNoNats.
  ///
  /// In en, this message translates to:
  /// **'No driver nationalities available for this equipment.'**
  String get msgNoNats;

  /// No description provided for @labelDriverNationality.
  ///
  /// In en, this message translates to:
  /// **'Driver nationality'**
  String get labelDriverNationality;

  /// No description provided for @labelDropoffAddress.
  ///
  /// In en, this message translates to:
  /// **'Drop-off address'**
  String get labelDropoffAddress;

  /// No description provided for @labelDropoffLat.
  ///
  /// In en, this message translates to:
  /// **'Drop-off latitude *'**
  String get labelDropoffLat;

  /// No description provided for @labelDropoffLon.
  ///
  /// In en, this message translates to:
  /// **'Drop-off longitude *'**
  String get labelDropoffLon;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @labelPriceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get labelPriceBreakdown;

  /// No description provided for @rowPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Per unit'**
  String get rowPerUnit;

  /// No description provided for @rowBase.
  ///
  /// In en, this message translates to:
  /// **'Base ({price} × {days} day)'**
  String rowBase(String price, String days);

  /// No description provided for @rowDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance ({pricePerKm} × {km} km)'**
  String rowDistance(String pricePerKm, String km);

  /// No description provided for @rowVat.
  ///
  /// In en, this message translates to:
  /// **'VAT {rate}%'**
  String rowVat(String rate);

  /// No description provided for @rowPerUnitTotal.
  ///
  /// In en, this message translates to:
  /// **'Per-unit total'**
  String get rowPerUnitTotal;

  /// No description provided for @rowQtyTimes.
  ///
  /// In en, this message translates to:
  /// **'× Quantity ({qty})'**
  String rowQtyTimes(int qty);

  /// No description provided for @rowSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get rowSubtotal;

  /// No description provided for @rowVatOnly.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get rowVatOnly;

  /// No description provided for @rowTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get rowTotal;

  /// No description provided for @rowDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get rowDownPayment;

  /// No description provided for @btnSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get btnSubmitting;

  /// No description provided for @btnSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get btnSubmit;

  /// No description provided for @rowFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {value}'**
  String rowFuel(String value);

  /// No description provided for @errChooseDates.
  ///
  /// In en, this message translates to:
  /// **'Please choose dates'**
  String get errChooseDates;

  /// No description provided for @infoSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get infoSignInFirst;

  /// No description provided for @errQtyMin.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1'**
  String get errQtyMin;

  /// No description provided for @errQtyAvail.
  ///
  /// In en, this message translates to:
  /// **'Only {count} piece(s) available'**
  String errQtyAvail(int count);

  /// No description provided for @errUnitSelectNat.
  ///
  /// In en, this message translates to:
  /// **'Unit {index}: Select a nationality'**
  String errUnitSelectNat(int index);

  /// No description provided for @errUnitLatLng.
  ///
  /// In en, this message translates to:
  /// **'Unit {index}: Drop-off lat/long required'**
  String errUnitLatLng(int index);

  /// No description provided for @errVendorMissing.
  ///
  /// In en, this message translates to:
  /// **'Vendor not found for this equipment.'**
  String get errVendorMissing;

  /// No description provided for @infoCreateOrgFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create/activate your Organization first.'**
  String get infoCreateOrgFirst;

  /// No description provided for @errLoadNatsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load equipment driver nationalities.'**
  String get errLoadNatsFailed;

  /// No description provided for @errLoadRespFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load responsibility names.'**
  String get errLoadRespFailed;

  /// No description provided for @errRequestAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Request/add failed'**
  String get errRequestAddFailed;

  /// No description provided for @requestCreated.
  ///
  /// In en, this message translates to:
  /// **'Request created'**
  String get requestCreated;

  /// No description provided for @unitIndex.
  ///
  /// In en, this message translates to:
  /// **'Unit {index}'**
  String unitIndex(int index);

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get noImages;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a place…'**
  String get mapSearchHint;

  /// No description provided for @mapNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get mapNoResults;

  /// No description provided for @mapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mapCancel;

  /// No description provided for @mapUseThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get mapUseThisLocation;

  /// No description provided for @mapExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get mapExpandTooltip;

  /// No description provided for @mapClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapClear;

  /// No description provided for @mapLatLabel.
  ///
  /// In en, this message translates to:
  /// **'Lat: {value}'**
  String mapLatLabel(String value);

  /// No description provided for @mapLngLabel.
  ///
  /// In en, this message translates to:
  /// **'Lng: {value}'**
  String mapLngLabel(String value);

  /// Login button text in app bar.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get actionLogin;

  /// Label for the auth button to sign out on the AppBar.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get actionLogout;

  /// No description provided for @sameDropoffForAll.
  ///
  /// In en, this message translates to:
  /// **'Same Drop-off Location'**
  String get sameDropoffForAll;

  /// Shown when a driver location is missing address
  ///
  /// In en, this message translates to:
  /// **'Unit {index}: please enter the drop-off address'**
  String errUnitAddress(int index);

  /// No description provided for @infoCompleteProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first.'**
  String get infoCompleteProfileFirst;

  /// No description provided for @leaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leave Empty For 0%'**
  String get leaveEmpty;

  /// No description provided for @errSelectEquipmentType.
  ///
  /// In en, this message translates to:
  /// **'Select an equipment type'**
  String get errSelectEquipmentType;

  /// No description provided for @errSelectEquipmentFromList.
  ///
  /// In en, this message translates to:
  /// **'Select an equipment from the list'**
  String get errSelectEquipmentFromList;

  /// No description provided for @errSelectFactory.
  ///
  /// In en, this message translates to:
  /// **'Select a factory'**
  String get errSelectFactory;

  /// No description provided for @errEnterDescriptionEnOrAr.
  ///
  /// In en, this message translates to:
  /// **'Enter a description (English or Arabic)'**
  String get errEnterDescriptionEnOrAr;

  /// No description provided for @errSelectFuelResponsibility.
  ///
  /// In en, this message translates to:
  /// **'Select fuel responsibility'**
  String get errSelectFuelResponsibility;

  /// No description provided for @errSelectTransferType.
  ///
  /// In en, this message translates to:
  /// **'Select transfer type'**
  String get errSelectTransferType;

  /// No description provided for @errSelectTransferResponsibility.
  ///
  /// In en, this message translates to:
  /// **'Select transfer responsibility'**
  String get errSelectTransferResponsibility;

  /// No description provided for @errSelectDriverTransport.
  ///
  /// In en, this message translates to:
  /// **'Select driver transport responsibility'**
  String get errSelectDriverTransport;

  /// No description provided for @errSelectDriverFood.
  ///
  /// In en, this message translates to:
  /// **'Select driver food responsibility'**
  String get errSelectDriverFood;

  /// No description provided for @errSelectDriverHousing.
  ///
  /// In en, this message translates to:
  /// **'Select driver housing responsibility'**
  String get errSelectDriverHousing;

  /// No description provided for @errPricePerDayGtZero.
  ///
  /// In en, this message translates to:
  /// **'Enter price per day (> 0).'**
  String get errPricePerDayGtZero;

  /// No description provided for @errPricePerHourGtZero.
  ///
  /// In en, this message translates to:
  /// **'Enter price per hour (> 0).'**
  String get errPricePerHourGtZero;

  /// No description provided for @errQuantityGteOne.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity (≥ 1).'**
  String get errQuantityGteOne;

  /// No description provided for @errPleaseCompleteForm.
  ///
  /// In en, this message translates to:
  /// **'Please complete the form'**
  String get errPleaseCompleteForm;

  /// No description provided for @errDescRequiredEnOrAr.
  ///
  /// In en, this message translates to:
  /// **'Required (EN or AR)'**
  String get errDescRequiredEnOrAr;

  /// No description provided for @errRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errRequired;

  /// No description provided for @failedToLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipment'**
  String get failedToLoadEquipment;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save them before leaving?'**
  String get unsavedChangesBody;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @pickIssueAndExpire.
  ///
  /// In en, this message translates to:
  /// **'Please pick both Issue and Expire dates.'**
  String get pickIssueAndExpire;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a Type.'**
  String get chooseType;

  /// No description provided for @chooseDocumentFile.
  ///
  /// In en, this message translates to:
  /// **'Please choose a document file.'**
  String get chooseDocumentFile;

  /// No description provided for @nameEnRequired.
  ///
  /// In en, this message translates to:
  /// **'Name (EN) *'**
  String get nameEnRequired;

  /// No description provided for @nameArRequired.
  ///
  /// In en, this message translates to:
  /// **'Name (AR) *'**
  String get nameArRequired;

  /// No description provided for @typeDomain10Required.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get typeDomain10Required;

  /// No description provided for @issueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Issue date *'**
  String get issueDateRequired;

  /// No description provided for @expireDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Expire date *'**
  String get expireDateRequired;

  /// No description provided for @deleteImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this image from the listing?'**
  String get deleteImageBody;

  /// No description provided for @deleteTermQ.
  ///
  /// In en, this message translates to:
  /// **'Delete term?'**
  String get deleteTermQ;

  /// No description provided for @addDriver.
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get addDriver;

  /// No description provided for @editDriver.
  ///
  /// In en, this message translates to:
  /// **'Edit driver'**
  String get editDriver;

  /// No description provided for @nationalityRequired.
  ///
  /// In en, this message translates to:
  /// **'Nationality *'**
  String get nationalityRequired;

  /// No description provided for @deleteDriverQ.
  ///
  /// In en, this message translates to:
  /// **'Delete driver?'**
  String get deleteDriverQ;

  /// No description provided for @addDriverFile.
  ///
  /// In en, this message translates to:
  /// **'Add driver file'**
  String get addDriverFile;

  /// No description provided for @serverFileName.
  ///
  /// In en, this message translates to:
  /// **'Server file name'**
  String get serverFileName;

  /// No description provided for @fileTypeIdRequired.
  ///
  /// In en, this message translates to:
  /// **'File type id *'**
  String get fileTypeIdRequired;

  /// No description provided for @startDateYmd.
  ///
  /// In en, this message translates to:
  /// **'Start yyyy-MM-dd'**
  String get startDateYmd;

  /// No description provided for @endDateYmd.
  ///
  /// In en, this message translates to:
  /// **'End yyyy-MM-dd'**
  String get endDateYmd;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @addFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {msg}'**
  String addFailedWithMsg(Object msg);

  /// Label for an optional file description field
  ///
  /// In en, this message translates to:
  /// **'File description Arabic (optional)'**
  String get fileDescriptionOptionalAr;

  /// Label for an optional file description field
  ///
  /// In en, this message translates to:
  /// **'File description English (optional)'**
  String get fileDescriptionOptionalEn;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @previewPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF preview'**
  String get previewPdf;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @pickAFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please pick and upload a file first'**
  String get pickAFileFirst;

  /// No description provided for @savingDots.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingDots;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get all;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired, please Sign In Again'**
  String get sessionExpired;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @errorLoadStatusDomain.
  ///
  /// In en, this message translates to:
  /// **'Could not load status names.'**
  String get errorLoadStatusDomain;

  /// No description provided for @errorInvalidRequestId.
  ///
  /// In en, this message translates to:
  /// **'Invalid request id.'**
  String get errorInvalidRequestId;

  /// No description provided for @errorUnitHasNoDriverForNationality.
  ///
  /// In en, this message translates to:
  /// **'At least one unit has no available drivers for its requested nationality.'**
  String get errorUnitHasNoDriverForNationality;

  /// No description provided for @errorUpdateFailedFlagFalse.
  ///
  /// In en, this message translates to:
  /// **'Update failed (flag=false).'**
  String get errorUpdateFailedFlagFalse;

  /// No description provided for @errorContractCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Contract creation failed.'**
  String get errorContractCreationFailed;

  /// No description provided for @snackContractCreated.
  ///
  /// In en, this message translates to:
  /// **'Contract created'**
  String get snackContractCreated;

  /// No description provided for @labelVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get labelVendor;

  /// No description provided for @labelCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get labelCustomer;

  /// No description provided for @labelIAmVendorQ.
  ///
  /// In en, this message translates to:
  /// **'I am vendor?'**
  String get labelIAmVendorQ;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @labelItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get labelItem;

  /// No description provided for @labelEquipmentId.
  ///
  /// In en, this message translates to:
  /// **'Equipment ID'**
  String get labelEquipmentId;

  /// No description provided for @labelWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get labelWeight;

  /// No description provided for @respFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get respFuel;

  /// No description provided for @respDriverFood.
  ///
  /// In en, this message translates to:
  /// **'Driver food'**
  String get respDriverFood;

  /// No description provided for @respDriverHousing.
  ///
  /// In en, this message translates to:
  /// **'Driver housing'**
  String get respDriverHousing;

  /// No description provided for @sectionStatusAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Status & Acceptance'**
  String get sectionStatusAcceptance;

  /// No description provided for @flagVendorAccepted.
  ///
  /// In en, this message translates to:
  /// **'Vendor accepted'**
  String get flagVendorAccepted;

  /// No description provided for @flagCustomerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Customer accepted'**
  String get flagCustomerAccepted;

  /// No description provided for @sectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sectionNotes;

  /// No description provided for @labelVendorNotes.
  ///
  /// In en, this message translates to:
  /// **'Vendor notes'**
  String get labelVendorNotes;

  /// No description provided for @labelCustomerNotes.
  ///
  /// In en, this message translates to:
  /// **'Customer notes'**
  String get labelCustomerNotes;

  /// No description provided for @sectionAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get sectionAttachments;

  /// No description provided for @sectionMeta.
  ///
  /// In en, this message translates to:
  /// **'Meta'**
  String get sectionMeta;

  /// No description provided for @labelRequestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get labelRequestId;

  /// No description provided for @labelRequestNo.
  ///
  /// In en, this message translates to:
  /// **'Request No.'**
  String get labelRequestNo;

  /// No description provided for @labelCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get labelCreatedAt;

  /// No description provided for @labelUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get labelUpdatedAt;

  /// No description provided for @fileType1.
  ///
  /// In en, this message translates to:
  /// **'Type {type}'**
  String fileType1(Object type);

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @driverWithId.
  ///
  /// In en, this message translates to:
  /// **'Driver #{id}'**
  String driverWithId(Object id);

  /// No description provided for @superAdmin_title.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin_title;

  /// No description provided for @superAdmin_tab_orgFiles.
  ///
  /// In en, this message translates to:
  /// **'Org Files'**
  String get superAdmin_tab_orgFiles;

  /// No description provided for @superAdmin_tab_orgUsers.
  ///
  /// In en, this message translates to:
  /// **'Org Users'**
  String get superAdmin_tab_orgUsers;

  /// No description provided for @superAdmin_tab_requestsOrders.
  ///
  /// In en, this message translates to:
  /// **'Requests / Orders'**
  String get superAdmin_tab_requestsOrders;

  /// No description provided for @superAdmin_tab_inactiveEquipments.
  ///
  /// In en, this message translates to:
  /// **'Inactive Equipments'**
  String get superAdmin_tab_inactiveEquipments;

  /// No description provided for @superAdmin_tab_inactiveOrgs.
  ///
  /// In en, this message translates to:
  /// **'Inactive Organizations'**
  String get superAdmin_tab_inactiveOrgs;

  /// No description provided for @superAdmin_gate_signIn_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get superAdmin_gate_signIn_title;

  /// No description provided for @superAdmin_gate_signIn_message.
  ///
  /// In en, this message translates to:
  /// **'This page is for Super Admin accounts.'**
  String get superAdmin_gate_signIn_message;

  /// No description provided for @superAdmin_gate_notAvailable_title.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get superAdmin_gate_notAvailable_title;

  /// No description provided for @superAdmin_gate_notAvailable_message.
  ///
  /// In en, this message translates to:
  /// **'Your account does not have Super Admin permission.'**
  String get superAdmin_gate_notAvailable_message;

  /// No description provided for @orgFiles_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search org files'**
  String get orgFiles_search_label;

  /// No description provided for @orgFiles_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete file?'**
  String get orgFiles_delete_title;

  /// No description provided for @orgFiles_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This will remove “{fileName}”.'**
  String orgFiles_delete_message(Object fileName);

  /// No description provided for @orgFiles_empty.
  ///
  /// In en, this message translates to:
  /// **'No organization files.'**
  String get orgFiles_empty;

  /// No description provided for @orgUsers_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search org users'**
  String get orgUsers_search_label;

  /// No description provided for @orgUsers_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove org user?'**
  String get orgUsers_remove_title;

  /// No description provided for @orgUsers_remove_message.
  ///
  /// In en, this message translates to:
  /// **'This will unlink user #{userId} from organization #{orgId}.'**
  String orgUsers_remove_message(Object orgId, Object userId);

  /// No description provided for @orgUsers_empty.
  ///
  /// In en, this message translates to:
  /// **'No organization users.'**
  String get orgUsers_empty;

  /// No description provided for @requests_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search requests / orders'**
  String get requests_search_label;

  /// No description provided for @requests_item_title.
  ///
  /// In en, this message translates to:
  /// **'Request #{id}'**
  String requests_item_title(Object id);

  /// No description provided for @requests_empty.
  ///
  /// In en, this message translates to:
  /// **'No requests found.'**
  String get requests_empty;

  /// No description provided for @inactiveEquipments_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search inactive equipments'**
  String get inactiveEquipments_search_label;

  /// No description provided for @inactiveEquipments_empty.
  ///
  /// In en, this message translates to:
  /// **'No inactive equipments.'**
  String get inactiveEquipments_empty;

  /// No description provided for @inactiveOrgs_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search inactive organizations'**
  String get inactiveOrgs_search_label;

  /// No description provided for @inactiveOrgs_empty.
  ///
  /// In en, this message translates to:
  /// **'No inactive organizations.'**
  String get inactiveOrgs_empty;

  /// No description provided for @action_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get action_signIn;

  /// No description provided for @action_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get action_back;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get action_remove;

  /// No description provided for @action_previewOpen.
  ///
  /// In en, this message translates to:
  /// **'Preview / Open'**
  String get action_previewOpen;

  /// No description provided for @action_activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get action_activate;

  /// No description provided for @action_deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get action_deactivate;

  /// No description provided for @action_openOrganization.
  ///
  /// In en, this message translates to:
  /// **'Open organization'**
  String get action_openOrganization;

  /// No description provided for @action_removeFromOrg.
  ///
  /// In en, this message translates to:
  /// **'Remove from org'**
  String get action_removeFromOrg;

  /// No description provided for @common_signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get common_signedIn;

  /// No description provided for @common_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get common_updated;

  /// No description provided for @common_updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get common_updateFailed;

  /// No description provided for @common_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get common_deleted;

  /// No description provided for @common_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get common_deleteFailed;

  /// No description provided for @common_removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get common_removed;

  /// No description provided for @common_removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get common_removeFailed;

  /// No description provided for @common_typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get common_typeToSearch;

  /// No description provided for @common_orgNumber.
  ///
  /// In en, this message translates to:
  /// **'Org #{id}'**
  String common_orgNumber(Object id);

  /// No description provided for @common_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get common_user;

  /// No description provided for @common_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get common_equipment;

  /// No description provided for @common_organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get common_organization;

  /// No description provided for @common_file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get common_file;

  /// No description provided for @common_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get common_status;

  /// No description provided for @common_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get common_active;

  /// No description provided for @common_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get common_inactive;

  /// No description provided for @common_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get common_expired;

  /// No description provided for @common_activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get common_activated;

  /// No description provided for @common_deactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get common_deactivated;

  /// No description provided for @superAdmin_tab_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get superAdmin_tab_overview;

  /// No description provided for @superAdmin_tab_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get superAdmin_tab_settings;

  /// No description provided for @superAdmin_tab_auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get superAdmin_tab_auditLogs;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @overview_totalOrgs.
  ///
  /// In en, this message translates to:
  /// **'Total organizations'**
  String get overview_totalOrgs;

  /// No description provided for @overview_totalEquipments.
  ///
  /// In en, this message translates to:
  /// **'Total equipments'**
  String get overview_totalEquipments;

  /// No description provided for @overview_totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get overview_totalUsers;

  /// No description provided for @overview_openRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get overview_openRequests;

  /// No description provided for @overview_quick_createOrg.
  ///
  /// In en, this message translates to:
  /// **'Create organization'**
  String get overview_quick_createOrg;

  /// No description provided for @overview_quick_inviteUser.
  ///
  /// In en, this message translates to:
  /// **'Invite user'**
  String get overview_quick_inviteUser;

  /// No description provided for @overview_quick_settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get overview_quick_settings;

  /// No description provided for @overview_recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get overview_recentActivity;

  /// No description provided for @settings_maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get settings_maintenanceMode;

  /// No description provided for @settings_maintenanceMode_desc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable the app for end users.'**
  String get settings_maintenanceMode_desc;

  /// No description provided for @settings_allowSignups.
  ///
  /// In en, this message translates to:
  /// **'Allow signups'**
  String get settings_allowSignups;

  /// No description provided for @settings_allowSignups_desc.
  ///
  /// In en, this message translates to:
  /// **'Permit new users to register accounts.'**
  String get settings_allowSignups_desc;

  /// No description provided for @settings_enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settings_enableNotifications;

  /// No description provided for @settings_enableNotifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Send system notifications to users.'**
  String get settings_enableNotifications_desc;

  /// No description provided for @settings_emptyOrError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded.'**
  String get settings_emptyOrError;

  /// No description provided for @audit_search_label.
  ///
  /// In en, this message translates to:
  /// **'Search audit logs'**
  String get audit_search_label;

  /// No description provided for @audit_empty.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found.'**
  String get audit_empty;

  /// No description provided for @audit_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get audit_filter_all;

  /// No description provided for @audit_filter_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get audit_filter_info;

  /// No description provided for @audit_filter_warn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get audit_filter_warn;

  /// No description provided for @audit_filter_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get audit_filter_error;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Type to search…'**
  String get search_hint;

  /// No description provided for @search_noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get search_noResults;

  /// Status label with a value
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String common_statusLabel(String status);

  /// No description provided for @common_organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get common_organizations;

  /// No description provided for @common_users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get common_users;

  /// No description provided for @common_equipments.
  ///
  /// In en, this message translates to:
  /// **'Equipments'**
  String get common_equipments;

  /// No description provided for @common_requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get common_requests;

  /// No description provided for @action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get action_save;

  /// No description provided for @common_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully.'**
  String get common_saved;

  /// No description provided for @common_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed.'**
  String get common_saveFailed;

  /// No description provided for @action_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get action_close;

  /// No description provided for @details_org_title.
  ///
  /// In en, this message translates to:
  /// **'Organization details'**
  String get details_org_title;

  /// No description provided for @details_equipment_title.
  ///
  /// In en, this message translates to:
  /// **'Equipment details'**
  String get details_equipment_title;

  /// No description provided for @common_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get common_details;

  /// No description provided for @common_id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get common_id;

  /// No description provided for @common_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get common_english;

  /// No description provided for @common_arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get common_arabic;

  /// No description provided for @details_notFound_org.
  ///
  /// In en, this message translates to:
  /// **'Organization details could not be loaded.'**
  String get details_notFound_org;

  /// No description provided for @details_notFound_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment details could not be loaded.'**
  String get details_notFound_equipment;

  /// No description provided for @common_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get common_image;

  /// No description provided for @common_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get common_images;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @noCalendarEvents.
  ///
  /// In en, this message translates to:
  /// **'No calendar events'**
  String get noCalendarEvents;

  /// No description provided for @event_eventOnDate.
  ///
  /// In en, this message translates to:
  /// **'{event} on {date}'**
  String event_eventOnDate(String event, String date);

  /// No description provided for @calendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming rentals and requests'**
  String get calendarSubtitle;

  /// No description provided for @requestCalendar.
  ///
  /// In en, this message translates to:
  /// **'Request Calendar'**
  String get requestCalendar;

  /// No description provided for @filterByEquipment.
  ///
  /// In en, this message translates to:
  /// **'Filter by Equipment'**
  String get filterByEquipment;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date Range'**
  String get filterByDate;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @selectEquipment.
  ///
  /// In en, this message translates to:
  /// **'Select Equipment'**
  String get selectEquipment;

  /// No description provided for @noEquipmentFound.
  ///
  /// In en, this message translates to:
  /// **'No equipment found'**
  String get noEquipmentFound;

  /// No description provided for @failedToLoadEquipments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipments'**
  String get failedToLoadEquipments;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @leaveChoiceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get leaveChoiceSave;

  /// No description provided for @leaveChoiceDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get leaveChoiceDiscard;

  /// No description provided for @leaveChoiceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get leaveChoiceCancel;

  /// No description provided for @deleteTermTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete term?'**
  String get deleteTermTitle;

  /// No description provided for @deleteEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete employee?'**
  String get deleteEmployeeTitle;

  /// No description provided for @deleteEmployeeBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name}.'**
  String deleteEmployeeBody(String name);

  /// No description provided for @employeeAdded.
  ///
  /// In en, this message translates to:
  /// **'Employee added'**
  String get employeeAdded;

  /// No description provided for @employeeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Employee updated'**
  String get employeeUpdated;

  /// No description provided for @employeeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Employee deleted'**
  String get employeeDeleted;

  /// No description provided for @couldNotSaveEmployee.
  ///
  /// In en, this message translates to:
  /// **'Could not save employee'**
  String get couldNotSaveEmployee;

  /// No description provided for @couldNotDeleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Could not delete employee'**
  String get couldNotDeleteEmployee;

  /// No description provided for @employeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesTitle;

  /// No description provided for @searchEmployeesHint.
  ///
  /// In en, this message translates to:
  /// **'Search employees'**
  String get searchEmployeesHint;

  /// No description provided for @searchHintEmployees.
  ///
  /// In en, this message translates to:
  /// **'e.g. Name, email, role…'**
  String get searchHintEmployees;

  /// No description provided for @addEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get addEmployeeTitle;

  /// No description provided for @editEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit employee'**
  String get editEmployeeTitle;

  /// No description provided for @roleTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role / Title'**
  String get roleTitleLabel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @statusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get statusHidden;

  /// No description provided for @failedToLoadEmployees.
  ///
  /// In en, this message translates to:
  /// **'Failed to load employees'**
  String get failedToLoadEmployees;

  /// No description provided for @noEmployeesYet.
  ///
  /// In en, this message translates to:
  /// **'No employees yet.'**
  String get noEmployeesYet;

  /// No description provided for @newEmployee.
  ///
  /// In en, this message translates to:
  /// **'New employee'**
  String get newEmployee;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// No description provided for @pleaseCompleteForm.
  ///
  /// In en, this message translates to:
  /// **'Please complete the form'**
  String get pleaseCompleteForm;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up.'**
  String get noNotificationsBody;

  /// No description provided for @seeAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'See all notifications'**
  String get seeAllNotifications;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
