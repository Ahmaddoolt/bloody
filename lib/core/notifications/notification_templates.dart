import 'package:easy_localization/easy_localization.dart';

/// Notification templates with emojis and engaging text
abstract class NotificationTemplates {
  NotificationTemplates._();

  static const Map<String, Map<String, Map<String, String>>> _templates = {
    'blood_request': {
      'en': {
        'title': '🩸 Blood Donation Needed',
        'body':
            'Urgent! Donors with blood type {blood_type} are needed in {city}. Your donation can save a life! 💪❤️',
      },
      'ar': {
        'title': '🩸 حاجة ملحّة للتبرع بالدم',
        'body':
            'عاجل! يُحتاج متبرعين بفصيلة دم {blood_type} في {city}. تبرعك يمكنه إنقاذ حياة! 💪❤️',
      },
    },
    'low_stock': {
      'en': {
        'title': '🚨 Low Blood Stock Alert',
        'body':
            'Critical shortage! {blood_type} blood stock at {center} is very low. Your help is urgently needed! 🏥⏰',
      },
      'ar': {
        'title': '🚨 تنبيه: انخفاض حاد في المخزون',
        'body':
            'نقص حرج! مخزون فصيلة {blood_type} في {center} منخفض جداً. نحتاج مساعدتك بشدة! 🏥⏰',
      },
    },
    'priority_request': {
      'en': {
        'title': '🔴 Priority Blood Request',
        'body':
            'Emergency! {blood_type} blood needed urgently in {city}. Please respond if you can donate! 🆘🙏',
      },
      'ar': {
        'title': '🔴 طلب دم ذو أولوية قصوى',
        'body':
            'حالة طوارئ! يُحتاج فصيلة {blood_type} بشكل عاجل في {city}. يرجى الاستجابة إذا كنت تستطيع التبرع! 🆘🙏',
      },
    },
    'donation_reminder': {
      'en': {
        'title': '✨ You Can Donate Again!',
        'body':
            'Great news! You are now eligible to donate blood again. Your contribution makes a difference! 🌟❤️',
      },
      'ar': {
        'title': '✨ يمكنك التبرع مجدداً!',
        'body':
            'أخبار رائعة! أنت الآن مؤهل للتبرع بالدم مرة أخرى. مساهمتك تصنع الفرق! 🌟❤️',
      },
    },
    'appointment_confirmed': {
      'en': {
        'title': '✅ Appointment Confirmed',
        'body':
            'Your donation appointment at {center} is confirmed for {date}. Thank you for being a hero! 🦸‍♂️💉',
      },
      'ar': {
        'title': '✅ تم تأكيد الموعد',
        'body':
            'تم تأكيد موعد تبرعك بالدم في {center} بتاريخ {date}. شكراً لأنك بطل! 🦸‍♂️💉',
      },
    },
    'donation_thanks': {
      'en': {
        'title': '🙏 Thank You for Donating!',
        'body':
            'Your blood donation is a gift of life. You\'ve made a real difference in someone\'s life today! ❤️✨',
      },
      'ar': {
        'title': '🙏 شكراً لتبرعك!',
        'body':
            'تبرعك بالدم هو هبة الحياة. لقد أحدثت فرقاً حقيقياً في حياة شخص ما اليوم! ❤️✨',
      },
    },
    'eligibility_reminder': {
      'en': {
        'title': '📅 Donation Eligibility Update',
        'body':
            'Only a few days left! You\'ll be eligible to donate blood again soon. Get ready to save lives! 🩸💪',
      },
      'ar': {
        'title': '📅 تحديث أهلية التبرع',
        'body':
            'بقيت أيام قليلة فقط! ستكون مؤهلاً للتبرع بالدم مرة أخرى قريباً. استعد لإنقاذ الأرواح! 🩸💪',
      },
    },
  };

  static String getTitle(String type, String language,
      {Map<String, String> params = const {}}) {
    final template = _templates[type]?[language] ?? _templates[type]?['en'];
    if (template == null) return type;

    return _interpolate(template['title']!, params);
  }

  static String getBody(String type, String language,
      {Map<String, String> params = const {}}) {
    final template = _templates[type]?[language] ?? _templates[type]?['en'];
    if (template == null) return type;

    return _interpolate(template['body']!, params);
  }

  static Map<String, String> getNotification(String type, String language,
      {Map<String, String> params = const {}}) {
    return {
      'title': getTitle(type, language, params: params),
      'body': getBody(type, language, params: params),
    };
  }

  static String _interpolate(String template, Map<String, String> params) {
    String result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  static List<String> get supportedTypes => _templates.keys.toList();

  static const String defaultLanguage = 'ar';
}
