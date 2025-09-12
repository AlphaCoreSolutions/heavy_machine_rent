// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
}
