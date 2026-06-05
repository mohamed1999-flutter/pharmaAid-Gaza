import 'package:flutter/material.dart';

import 'app_keys.dart';

class AppTexts {
  static const supportedLocales = [Locale('ar'), Locale('en')];

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      AppKeys.appName: 'PharmaAid Gaza',
      AppKeys.skip: 'تخطي',

      AppKeys.welcomeToApp: 'مرحباً بك في تطبيق شفاء',
      AppKeys.loginByPhone: 'التسجيل من خلال الهاتف',
      AppKeys.loginDescription:
          'من خلال إنشاء حسابك في تطبيق PharmaAid Gaza فإنك توافق على الأحكام والشروط',

      AppKeys.offers: 'العروض',
      AppKeys.featuredOffers: 'عروض مميزة',
      AppKeys.skincareOffers: 'اسعافات أولية',
      AppKeys.medicalSupplies: 'المستلزمات',
      AppKeys.babyCare: 'عناية بالرضع',
      AppKeys.personalCare: 'عناية شخصية',
      AppKeys.pharmacyEssentials: 'عناية بالبشرة',
      AppKeys.showDiscount: 'خصم %10',
      AppKeys.addToCart: 'أضف للعربة',
      AppKeys.shopNow: 'تسوق الآن',
      AppKeys.trending: 'رائج',
      AppKeys.seasonal: 'موسمي',
      AppKeys.bestValue: 'أفضل قيمة',
      AppKeys.newArrivals: 'وصل حديثًا',
      AppKeys.soldOut: 'نفد',
      AppKeys.seeAll: 'عرض الكل',
      AppKeys.language: 'اللغة',
      AppKeys.mode: 'الوضع',
      AppKeys.arabic: 'العربية',
      AppKeys.english: 'English',
      AppKeys.morning: 'صباحي',
      AppKeys.night: 'ليلي',
      AppKeys.next: 'التالي',

      AppKeys.shoppingHeadline: 'مرحباً بك في تطبيق شفاء',
      AppKeys.shoppingSubheadline:
          'من خلال إنشاء حسابك في تطبيق PharmaAid Gaza فإنك توافق على الأحكام والشروط',

      AppKeys.terms: 'الأحكام والشروط',
      AppKeys.continueText: 'متابعة',
      AppKeys.getStarted: 'ابدأ الآن',

      AppKeys.searchHint: 'ابحث عن الدواء',
      AppKeys.hiAhmed: 'مرحبا أحمد',
      AppKeys.viewAll: 'استعراض الكل',
      AppKeys.topPharmacies: 'الصيدليات الأشهر',
      AppKeys.categories: 'الأقسام',
      AppKeys.brands: 'الماركات',
      AppKeys.viewAllBrands: 'عرض كل الماركات',
      AppKeys.bestSellers: 'الأكثر مبيعاً',
      AppKeys.home: 'الرئيسية',
      AppKeys.pharmacies: 'الصيدليات',
      AppKeys.profile: 'الملف الشخصي',
      AppKeys.topPharmaciesTitle: 'الصيدليات الأشهر',
      AppKeys.pharmacy1Title: 'صيدلية عادل',
      AppKeys.pharmacy1Subtitle:
          'صيدلية عادل في مدينة فلسطين لكل أنواع الأدوية\nالمتاحة ذات الأمان العالي',
      AppKeys.pharmacy2Title: 'صيدلية السرايا',
      AppKeys.pharmacy2Subtitle:
          'صيدلية السرايا في مدينة فلسطين لكل أنواع الأدوية\nالمتاحة ذات الأمان العالي',
      AppKeys.pharmacy3Title: 'صيدلية الرمال',
      AppKeys.pharmacy3Subtitle:
          'صيدلية الرمال في مدينة فلسطين لكل أنواع الأدوية\nالمتاحة ذات الأمان العالي',

      AppKeys.categoryMedicine: 'أدوية',
      AppKeys.categoryWomen: 'العناية بالمرأة',
      AppKeys.categoryMen: 'العناية بالرجل',
      AppKeys.categoryChild: 'العناية بالطفل',
      AppKeys.categoryDental: 'العناية بالأسنان',
      AppKeys.categorySkin: 'العناية بالبشرة',
      AppKeys.categoryHerbs: 'أعشاب',
      AppKeys.categoryWounds: 'جروح',

      AppKeys.banner1Title: 'عرض خاص\nلمدينة عادل',
      AppKeys.banner1Subtitle:
          'اشتري بقيمة 50 شيكل واحصل\nخصم 50% على باقي الفاتورة',
      AppKeys.banner2Title: 'خصومات قوية',
      AppKeys.banner2Subtitle: 'عروض يومية على منتجات العناية',
      AppKeys.banner3Title: 'تسوق الآن',
      AppKeys.banner3Subtitle: 'أفضل الأدوية والماركات الأصلية',

      AppKeys.bestSeller1Title: 'كريم أوريجينال',
      AppKeys.bestSeller2Title: 'مرطب للبشرة الحساسة',
      AppKeys.switchSystem: 'تبديل النظام',
      AppKeys.switchSystemTitle: 'هل تريد تبديل النظام؟',
      AppKeys.switchSystemMessage: 'هل تريد أن تبدّل إلى نظام صيدلية؟',
      AppKeys.yes: 'نعم',
      AppKeys.no: 'لا',

      AppKeys.login: 'تسجيل الدخول',
      AppKeys.register: 'إنشاء حساب',
      AppKeys.fullName: 'الاسم',
      AppKeys.email: 'البريد الإلكتروني',
      AppKeys.password: 'كلمة المرور',
      AppKeys.confirmPassword: 'تأكيد كلمة المرور',
      AppKeys.pharmacyName: 'اسم الصيدلية',
      AppKeys.pharmacyAddress: 'عنوان الصيدلية',
      AppKeys.pharmacyImageUrl: 'رابط صورة الصيدلية',
      AppKeys.signIn: 'دخول',
      AppKeys.createAccount: 'إنشاء الحساب',
      AppKeys.logout: 'تسجيل الخروج',

      AppKeys.theme: 'المظهر',

      AppKeys.medicines: 'الأدوية',
      AppKeys.orders: 'الطلبات',

      AppKeys.add: 'إضافة',
      AppKeys.delete: 'حذف',
      AppKeys.save: 'حفظ',
      AppKeys.status: 'الحالة',
      AppKeys.pending: 'قيد الانتظار',
      AppKeys.accepted: 'مقبول',
      AppKeys.rejected: 'مرفوض',
      AppKeys.preparing: 'يتم التجهيز',
      AppKeys.delivered: 'تم التسليم',
    },
    'en': {
      AppKeys.appName: 'PharmaAid Gaza',
      AppKeys.skip: 'Skip',

      AppKeys.welcomeToApp: 'Welcome to Shifa app',
      AppKeys.loginByPhone: 'Sign up with phone',
      AppKeys.loginDescription:
          'By creating your account in the PharmaAid Gaza app, you agree to the terms and conditions',

      AppKeys.language: 'Language',
      AppKeys.mode: 'Mode',
      AppKeys.arabic: 'Arabic',
      AppKeys.english: 'English',
      AppKeys.morning: 'Morning',
      AppKeys.night: 'Night',
      AppKeys.next: 'Next',
      AppKeys.offers: 'Offers',
      AppKeys.featuredOffers: 'Featured offers',
      AppKeys.skincareOffers: 'First aid',
      AppKeys.medicalSupplies: 'Supplies',
      AppKeys.babyCare: 'Baby care',
      AppKeys.personalCare: 'Personal care',
      AppKeys.pharmacyEssentials: 'Skincare',
      AppKeys.showDiscount: '10% off',
      AppKeys.addToCart: 'Add to cart',
      AppKeys.shopNow: 'Shop now',
      AppKeys.trending: 'Trending',
      AppKeys.seasonal: 'Seasonal',
      AppKeys.bestValue: 'Best value',
      AppKeys.newArrivals: 'New arrivals',
      AppKeys.soldOut: 'Sold out',
      AppKeys.seeAll: 'See all',
      AppKeys.shoppingHeadline: 'Welcome to Shifa app',
      AppKeys.shoppingSubheadline:
          'By creating your account in the PharmaAid Gaza app, you agree to the terms and conditions',

      AppKeys.terms: 'Terms and conditions',
      AppKeys.continueText: 'Continue',
      AppKeys.getStarted: 'Get started',

      AppKeys.searchHint: 'Search for medicine',
      AppKeys.hiAhmed: 'Hi Ahmed',
      AppKeys.viewAll: 'View all',
      AppKeys.topPharmacies: 'Top pharmacies',
      AppKeys.categories: 'Categories',
      AppKeys.brands: 'Brands',
      AppKeys.viewAllBrands: 'View all brands',
      AppKeys.bestSellers: 'Best sellers',

      AppKeys.home: 'Home',
      AppKeys.pharmacies: 'Pharmacies',

      AppKeys.profile: 'Profile',

      AppKeys.topPharmaciesTitle: 'Top pharmacies',
      AppKeys.pharmacy1Title: 'Adel Pharmacy',
      AppKeys.pharmacy1Subtitle:
          'Adel pharmacy in Palestine city for all types of medicine\nwith high safety standards',
      AppKeys.pharmacy2Title: 'Al Saraya Pharmacy',
      AppKeys.pharmacy2Subtitle:
          'Al Saraya pharmacy in Palestine city for all types of medicine\nwith high safety standards',
      AppKeys.pharmacy3Title: 'Al Rimal Pharmacy',
      AppKeys.pharmacy3Subtitle:
          'Al Rimal pharmacy in Palestine city for all types of medicine\nwith high safety standards',

      AppKeys.categoryMedicine: 'Medicine',
      AppKeys.categoryWomen: 'Women care',
      AppKeys.categoryMen: 'Men care',
      AppKeys.categoryChild: 'Child care',
      AppKeys.categoryDental: 'Dental care',
      AppKeys.categorySkin: 'Skin care',
      AppKeys.categoryHerbs: 'Herbs',
      AppKeys.categoryWounds: 'Wounds',

      AppKeys.banner1Title: 'Special offer\nFor Adel',
      AppKeys.banner1Subtitle:
          'Buy for 50 ILS and get\n50% off the rest of the bill',
      AppKeys.banner2Title: 'Big discounts',
      AppKeys.banner2Subtitle: 'Daily deals on care products',
      AppKeys.banner3Title: 'Shop now',
      AppKeys.banner3Subtitle: 'Best medicines and original brands',

      AppKeys.bestSeller1Title: 'Original cream',
      AppKeys.bestSeller2Title: 'Sensitive skin moisturizer',
      AppKeys.switchSystem: 'Switch system',
      AppKeys.switchSystemTitle: 'Do you want to switch system?',
      AppKeys.switchSystemMessage: 'Do you want to switch to pharmacy system?',
      AppKeys.yes: 'Yes',
      AppKeys.no: 'No',

      AppKeys.login: 'Login',
      AppKeys.register: 'Register',
      AppKeys.fullName: 'Full name',
      AppKeys.email: 'Email',
      AppKeys.password: 'Password',
      AppKeys.confirmPassword: 'Confirm password',
      AppKeys.pharmacyName: 'Pharmacy name',
      AppKeys.pharmacyAddress: 'Pharmacy address',
      AppKeys.pharmacyImageUrl: 'Pharmacy image URL',
      AppKeys.signIn: 'Sign in',
      AppKeys.createAccount: 'Create account',
      AppKeys.logout: 'Logout',

      AppKeys.theme: 'Theme',

      AppKeys.medicines: 'Medicines',
      AppKeys.orders: 'Orders',

      AppKeys.add: 'Add',
      AppKeys.delete: 'Delete',
      AppKeys.save: 'Save',
      AppKeys.status: 'Status',
      AppKeys.pending: 'Pending',
      AppKeys.accepted: 'Accepted',
      AppKeys.rejected: 'Rejected',
      AppKeys.preparing: 'Preparing',
      AppKeys.delivered: 'Delivered',
    },
  };

  static String tr(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _values[code]?[key] ?? _values['en']![key] ?? key;
  }
}
