// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}
