import 'package:flutter/material.dart';

import '../data/demo_products.dart';

/// The English text is the key. Keeping both languages here makes student edits easy.
class AppStrings {
  const AppStrings(this.language);
  final String language;
  bool get isArabic => language == 'ar';
  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);
  static final Set<String> untranslated = {};

  String t(String value) {
    if (!isArabic) return value;
    if (arabic.containsKey(value)) return arabic[value]!;
    for (final product in demoProducts) {
      if (value == product.name) return product.nameAr;
      if (value == product.description) return product.descriptionAr;
      if (value == product.brand || value == product.brand.toUpperCase()) {
        return value;
      }
    }
    final patterns = <(String, String Function(RegExpMatch))>[
      (r'^(\d+) essentials to explore$', (m) => '${m[1]} منتجات بانتظارك'),
      (
        r'^(\d+) items picked\. Looking good!$',
        (m) => '${m[1]} منتجات في عربتك. اختيار موفق!',
      ),
      (r'^View cart · (\d+) items$', (m) => 'عرض العربة · ${m[1]} منتجات'),
      (
        r'^Add another · (\d+) in cart$',
        (m) => 'أضف قطعة أخرى · ${m[1]} في العربة',
      ),
      (r'^(.+) added to cart\.$', (m) => 'تمت إضافة ${t(m[1]!)} إلى العربة.'),
      (r'^Demo nutrition • (.+)$', (m) => 'قيم غذائية تجريبية • ${t(m[1]!)}'),
      (r'^Remove (.+)$', (m) => 'حذف ${t(m[1]!)}'),
      (r'^Increase (.+)$', (m) => 'زيادة كمية ${t(m[1]!)}'),
      (r'^Decrease (.+)$', (m) => 'تقليل كمية ${t(m[1]!)}'),
      (r'^(.+) package illustration$', (m) => 'صورة عبوة ${t(m[1]!)}'),
    ];
    for (final entry in patterns) {
      final match = RegExp(entry.$1).firstMatch(value);
      if (match != null) return entry.$2(match);
    }
    if (value.contains(' / ')) return value.split(' / ').map(t).join(' / ');
    if (RegExp(r'^[\d.]+ (g|ml|L)$').hasMatch(value)) {
      return value
          .replaceAll(' g', ' غ')
          .replaceAll(' ml', ' مل')
          .replaceAll(' L', ' لتر');
    }
    if (value.contains('SAR ')) {
      return value
          .replaceAll('SAR ', 'ر.س ')
          .replaceAll(' each', ' للقطعة')
          .replaceAll(' ml', ' مل')
          .replaceAll(' L', ' لتر')
          .replaceAll(' g', ' غ');
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        value.startsWith('SMARTCART:') ||
        value.startsWith('SC-') ||
        RegExp(r'^P\d{3}$').hasMatch(value) ||
        value == 'SmartCart') {
      return value;
    }
    untranslated.add(value);
    return value;
  }

  static const arabic = <String, String>{
    'Scan a product label to explore its details.':
        'امسح ملصق المنتج لاستكشاف تفاصيله.',
    'Product not found': 'المنتج غير موجود',
    'This product link is invalid or no longer available.':
        'رابط المنتج غير صالح أو لم يعد متاحاً.',
    'Explore with a scan.': 'اكتشف المنتج بمسح الرمز.',
    'Scan a product label to view its details. Add it to your cart when you are ready.':
        'امسح ملصق المنتج لعرض تفاصيله. أضفه إلى عربتك عندما ترغب.',
    'Scanning opens product details. It does not add the product to your cart.':
        'المسح يفتح تفاصيل المنتج ولا يضيفه إلى عربتك.',
    'Enter a product URL or ID.': 'أدخل رابط المنتج أو معرّفه.',
    'Product URL or ID': 'رابط المنتج أو معرّفه',
    'View product': 'عرض المنتج',
    'Use the Add button to put a product in your cart.':
        'استخدم زر الإضافة لوضع المنتج في عربتك.',
    'Your phone opens product details. Only the Add button changes your cart.':
        'يفتح الهاتف تفاصيل المنتج. زر الإضافة وحده يضيفه إلى العربة.',
    'smart cart': 'SmartCart',
    'DEMO': 'نسخة تجريبية',
    'Products': 'المنتجات',
    'Scan': 'المسح',
    'Cart': 'العربة',
    'Settings': 'الإعدادات',
    'A little smarter. A lot easier.': 'تسوّق أذكى. حياة أسهل.',
    'Your everyday shop,\nreimagined.': 'تسوّقك اليومي،\nبطريقة أذكى.',
    'Pick your favourites. Scan as you go.\nEnjoy a simpler way to fill your cart.':
        'اختر ما تحب وامسح الرمز أثناء التسوّق.\nتجربة أسهل لملء عربتك.',
    'Start shopping': 'ابدأ التسوّق',
    'Try the scanner': 'جرّب الماسح',
    'A fresh take on your grocery trip': 'تجربة جديدة لتسوّق احتياجاتك',
    'Less waiting, more living': 'انتظار أقل، وقت أكثر لك',
    'Good shopping. Three simple steps.': 'تسوّق مريح في ثلاث خطوات.',
    'Discover your essentials': 'اكتشف احتياجاتك',
    'Browse familiar favourites and see what is inside.':
        'تصفّح منتجاتك المفضلة وتعرّف على مكوناتها.',
    'Scan. Add. Keep going.': 'امسح. أضف. واصل التسوّق.',
    'Scan a product QR label and watch your cart update.':
        'امسح رمز المنتج وشاهد عربتك تتحدث فوراً.',
    'Leave with a little ease': 'أكمل رحلتك بسهولة',
    'Review your total and get an instant demo receipt.':
        'راجع الإجمالي واحصل على إيصال تجريبي فوري.',
    'Graduation project prototype. Prices and nutrition are editable demo data. Checkout is simulated.': 'نموذج لمشروع تخرج. الأسعار والقيم الغذائية تجريبية وقابلة للتعديل. إتمام الشراء محاكاة.',
    'The everyday collection': 'اختياراتك اليومية',
    'Fresh picks for your cart': 'اختيارات طازجة لعربتك',
    'A few familiar favourites. A smarter way to shop.':
        'منتجات مألوفة تحبها. وطريقة أذكى للتسوّق.',
    'Search your essentials': 'ابحث عن احتياجاتك',
    'All products': 'كل المنتجات',
    'All': 'الكل',
    'Dairy': 'الألبان',
    'Drinks': 'المشروبات',
    'Snacks': 'الوجبات الخفيفة',
    'No products found. Try another name or category.':
        'لم نعثر على منتجات. جرّب اسماً أو فئة أخرى.',
    'Demo products and prices. Nutrition is illustrative; check the actual package for accurate information.': 'الأسعار والقيم الغذائية تجريبية. راجع العبوة الفعلية للحصول على معلومات دقيقة.',
    'Add to cart': 'أضف إلى العربة',
    'Product details': 'تفاصيل المنتج',
    'A look inside': 'القيم الغذائية',
    'Calories (kcal)': 'السعرات الحرارية',
    'Protein': 'البروتين',
    'Carbohydrates': 'الكربوهيدرات',
    'Fat': 'الدهون',
    'per 100 ml': 'لكل 100 مل',
    'per 50 g pack': 'لكل عبوة 50 غ',
    'per 48 g pack': 'لكل عبوة 48 غ',
    'Product QR code': 'رمز المنتج',
    'Illustrative nutrition and packaging. Refer to the real product label for dietary decisions.': 'القيم الغذائية تجريبية. راجع ملصق العبوة الحقيقية لمعرفة المعلومات الغذائية الدقيقة.',
    'Your shopping companion': 'رفيقك في التسوّق',
    'Scan it. Cart it.': 'امسح الرمز. أضف للعربة.',
    'Scan a SmartCart QR label, or use the manual options below.':
        'امسح رمز منتج SmartCart أو استخدم الخيارات اليدوية أدناه.',
    'Camera QR scanner': 'ماسح رموز الكاميرا',
    'Start camera': 'تشغيل الكاميرا',
    'Stop camera': 'إيقاف الكاميرا',
    'Camera permission': 'إذن استخدام الكاميرا',
    'Allow camera access to scan product QR labels. Video stays on your device and is never uploaded.': 'اسمح باستخدام الكاميرا لمسح رموز المنتجات. يبقى الفيديو على جهازك ولا يتم رفعه.',
    'Point the camera at a product QR label.': 'وجّه الكاميرا إلى رمز المنتج.',
    'Move the QR code away for 2 seconds before scanning it again.':
        'أبعد الرمز عن الكاميرا لمدة ثانيتين قبل مسحه مرة أخرى.',
    'Camera needs HTTPS. Open the public website to scan on your iPhone. Manual entry still works here.': 'تحتاج الكاميرا إلى اتصال HTTPS. افتح الموقع العام للمسح على آيفون. الإدخال اليدوي متاح هنا.',
    'Camera access was denied. Allow Camera in Safari website settings, then try again.': 'تم رفض إذن الكاميرا. اسمح بالكاميرا من إعدادات الموقع في سفاري ثم حاول مجدداً.',
    'No camera is available. Use manual QR entry or select a product below.':
        'لا توجد كاميرا متاحة. أدخل الرمز يدوياً أو اختر منتجاً أدناه.',
    'Unable to start the camera. Close other camera apps and try again, or use manual entry.': 'تعذر تشغيل الكاميرا. أغلق التطبيقات التي تستخدمها وحاول مجدداً، أو استخدم الإدخال اليدوي.',
    'Starting camera…': 'جارٍ تشغيل الكاميرا…',
    'Try again': 'حاول مجدداً',
    'Enter a QR payload': 'أدخل محتوى رمز المنتج',
    'Scan QR code': 'مسح رمز المنتج',
    'Scanning…': 'جارٍ المسح…',
    'Or, choose a product': 'أو اختر منتجاً',
    'Tap Scan to add one. Scan again to add another.':
        'اضغط على المسح لإضافة قطعة. امسح مجدداً لإضافة قطعة أخرى.',
    'Each scan adds one item. Your running total is always available in Cart.':
        'كل عملية مسح تضيف قطعة واحدة. يمكنك مراجعة الإجمالي في العربة.',
    'Enter a QR payload to scan.': 'أدخل محتوى رمز المنتج للمسح.',
    'Unknown or invalid QR code. Use a SmartCart product label.':
        'رمز غير معروف أو غير صالح. استخدم ملصق منتج SmartCart.',
    'Scanner unavailable. Please try again.': 'الماسح غير متاح. حاول مجدداً.',
    'Your shopping trip': 'رحلتك للتسوّق',
    'A cart full of good things': 'عربة مليئة باختياراتك',
    'Your next favourite is just a scan away.': 'منتجك المفضل التالي ينتظرك.',
    'Your cart is feeling light': 'عربتك فارغة حالياً',
    'Browse the essentials or scan a demo product\nto start your shopping trip.':
        'تصفّح المنتجات أو امسح رمز منتج\nلبدء رحلة التسوّق.',
    'Explore products': 'استكشف المنتجات',
    'Your trip at a glance': 'ملخص رحلتك',
    'Items': 'المنتجات',
    'Subtotal': 'المجموع الفرعي',
    'Additional charges': 'رسوم إضافية',
    'Total': 'الإجمالي',
    'Continue to checkout': 'المتابعة لإتمام الشراء',
    'Demo checkout. No real payment or additional charges.':
        'إتمام شراء تجريبي، دون دفع حقيقي أو رسوم إضافية.',
    'Checkout': 'إتمام الشراء',
    'One last look': 'نظرة أخيرة',
    'All set to check out?': 'هل أنت مستعد لإتمام الشراء؟',
    'Review your picks and finish your demo shopping trip.':
        'راجع اختياراتك وأكمل رحلة التسوّق التجريبية.',
    'Order summary': 'ملخص الطلب',
    'Total items': 'إجمالي القطع',
    'Just a demo. All the convenience.': 'تجربة تجريبية بكل سهولة.',
    'No payment details needed. Completing this order creates a sample receipt and clears your cart.': 'لا تحتاج إلى بيانات دفع. عند إتمام الطلب يُنشأ إيصال تجريبي وتُفرغ العربة.',
    'Complete demo checkout': 'إتمام الشراء التجريبي',
    'This is a simulated purchase. No money will be charged.':
        'هذه عملية شراء تجريبية. لن يُخصم أي مبلغ.',
    'Your receipt': 'إيصالك',
    'You’re good to go!': 'تمت رحلتك بنجاح!',
    'A smarter shop, from first scan to last item.':
        'تسوّق أذكى، من أول رمز إلى آخر منتج.',
    'Smart Cart / Demo receipt': 'SmartCart / إيصال تجريبي',
    'ORDER NUMBER': 'رقم الطلب',
    'SIMULATED · NO PAYMENT TAKEN': 'عملية تجريبية · لم يتم الدفع',
    'Thank you for shopping a little smarter.': 'شكراً لاختيارك التسوّق بذكاء.',
    'Start New Shopping Trip': 'ابدأ رحلة تسوّق جديدة',
    'Keep a screenshot if you need a copy. Your signed-in orders are saved in Order history.':
        'احتفظ بصورة للإيصال عند الحاجة. تُحفظ طلبات الحساب في سجل الطلبات.',
    'local time': 'التوقيت المحلي',
    'Product QR Labels': 'ملصقات رموز المنتجات',
    'Ready for your demo': 'جاهز لعرض مشروعك',
    'Print these labels or save a PDF, then scan them with another device.':
        'اطبع هذه الملصقات أو احفظ ملف PDF ثم امسحها باستخدام جهاز آخر.',
    'Print labels': 'طباعة الملصقات',
    'Save PDF': 'حفظ PDF',
    'Preparing labels…': 'جارٍ تجهيز الملصقات…',
    'Unable to prepare the labels. Please try again.':
        'تعذر تجهيز الملصقات. حاول مجدداً.',
    'Product ID': 'معرّف المنتج',
    'QR payload': 'محتوى الرمز',
    'Scan to add to your cart': 'امسح لإضافته إلى العربة',
    'Make yourself at home': 'أهلاً بك',
    'Shop freely. An account is always optional.':
        'تسوّق بحرية. إنشاء الحساب اختياري دائماً.',
    'Continue as Guest': 'المتابعة كضيف',
    'Create Account': 'إنشاء حساب',
    'Sign In': 'تسجيل الدخول',
    'Sign Out': 'تسجيل الخروج',
    'Forgot Password': 'نسيت كلمة المرور',
    'Account': 'الحساب',
    'Guest': 'ضيف',
    'Guest shopping': 'التسوّق كضيف',
    'Profile': 'الملف الشخصي',
    'Display name (optional)': 'الاسم المعروض (اختياري)',
    'Email address': 'البريد الإلكتروني',
    'Password': 'كلمة المرور',
    'Save profile': 'حفظ الملف الشخصي',
    'Profile updated.': 'تم تحديث الملف الشخصي.',
    'Order history': 'سجل الطلبات',
    'No orders yet': 'لا توجد طلبات بعد',
    'Your completed orders will appear here when you shop while signed in.':
        'ستظهر طلباتك المكتملة هنا عند التسوّق بعد تسجيل الدخول.',
    'Language': 'اللغة',
    'English': 'الإنجليزية',
    'Arabic': 'العربية',
    'About SmartCart': 'عن SmartCart',
    'Privacy notice': 'إشعار الخصوصية',
    'SmartCart is a university graduation prototype for QR-assisted supermarket shopping. All payments are simulated. Prices and nutrition are editable demo data.': 'SmartCart نموذج لمشروع تخرج جامعي للتسوّق باستخدام رموز المنتجات. جميع عمليات الدفع محاكاة، والأسعار والقيم الغذائية بيانات تجريبية قابلة للتعديل.',
    'Guest carts and language preferences are saved in this browser. Account passwords are handled by Firebase Authentication, never stored by this app. Signed-in order history is currently stored on this device, separately for each account. Camera frames stay on your device. No real payment data is collected.': 'تُحفظ عربة الضيف واللغة في هذا المتصفح. تتولى خدمة Firebase Authentication معالجة كلمات المرور ولا يحفظها التطبيق. يُحفظ سجل الطلبات حالياً على هذا الجهاز بشكل منفصل لكل حساب. تبقى صور الكاميرا على جهازك ولا تُجمع بيانات دفع حقيقية.',
    'Your cart is saved on this device. No account needed.':
        'تُحفظ عربتك على هذا الجهاز. لا حاجة إلى حساب.',
    'Account setup is not complete yet. Continue shopping as a guest.':
        'لم يكتمل إعداد الحسابات بعد. يمكنك مواصلة التسوّق كضيف.',
    'Use at least 8 characters for your password.':
        'استخدم 8 أحرف على الأقل لكلمة المرور.',
    'Please enter a valid email address.': 'يرجى إدخال بريد إلكتروني صالح.',
    'Please enter your password.': 'يرجى إدخال كلمة المرور.',
    'Password is too weak. Use at least 8 characters.':
        'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.',
    'The email or password is incorrect.':
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'This email already has an account. Try signing in.':
        'يوجد حساب بهذا البريد. جرّب تسجيل الدخول.',
    'Too many attempts. Please wait and try again.':
        'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.',
    'Check your connection and try again.': 'تحقق من الاتصال وحاول مجدداً.',
    'Email/password sign-in is not enabled for this project yet.':
        'لم يُفعّل تسجيل الدخول بالبريد وكلمة المرور لهذا المشروع بعد.',
    'Account action failed. Please try again.':
        'تعذر إكمال إجراء الحساب. حاول مجدداً.',
    'This account has been disabled.': 'تم تعطيل هذا الحساب.',
    'Working…': 'جارٍ التنفيذ…',
    'Send reset link': 'إرسال رابط إعادة التعيين',
    'Enter your email to receive a password reset link.':
        'أدخل بريدك الإلكتروني لاستلام رابط إعادة تعيين كلمة المرور.',
    'If an account exists for this email, a reset link has been sent.':
        'إذا وُجد حساب بهذا البريد فقد أُرسل رابط إعادة التعيين.',
    'Signed out. Guest shopping is ready.':
        'تم تسجيل الخروج. يمكنك التسوّق كضيف.',
    'Account connection unavailable. Please try again.':
        'الاتصال بالحساب غير متاح. حاول مجدداً.',
    'Preferences could not be saved on this device.':
        'تعذر حفظ التفضيلات على هذا الجهاز.',
    'Order history could not be saved on this device.':
        'تعذر حفظ سجل الطلبات على هذا الجهاز.',
    'Close': 'إغلاق',
    'Back': 'رجوع',
    'Save': 'حفظ',
    'Loading…': 'جارٍ التحميل…',
    'Fresh favourites, thoughtfully picked.': 'منتجات تحبها، اخترناها بعناية.',
    'Everyday essentials': 'احتياجاتك اليومية',
    'Your next great grocery trip starts here.':
        'رحلتك القادمة للتسوّق تبدأ هنا.',
    'Shop the collection': 'تسوّق المجموعة',
  };
}

extension TranslatedContext on BuildContext {
  String tr(String text) => AppStrings.of(this).t(text);
}

class LText extends StatelessWidget {
  const LText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    textDirection: textDirection,
  );
}
