# Notification Setup Guide

## Issue: Notification Icons Not Showing on Xiaomi/Chinese Devices

### Problem
Xiaomi and other Chinese Android devices require explicit notification icon configuration in AndroidManifest.xml. Without proper setup, notifications appear without icons or with default system icons.

### Solution Implemented

1. **Created Notification Icon Drawable** (`android/app/src/main/res/drawable/ic_notification.xml`)
   - Simple white blood drop icon on transparent background
   - Vector drawable that scales properly on all devices
   - Follows Android notification icon guidelines (white/transparent only)

2. **Updated AndroidManifest.xml**
   - Added `com.google.firebase.messaging.default_notification_icon` metadata
   - Added `com.google.firebase.messaging.default_notification_color` metadata
   - Added `com.google.firebase.messaging.default_notification_channel_id` metadata

3. **Notification Channel Configuration**
   - Channel ID: `blood_donation_alerts`
   - Important for Android 8.0+ (API 26+)

### For Production (Recommended)

Replace the default vector icon with a proper notification icon set:

1. Create a simple white blood drop icon (PNG format)
2. Use Android Studio's "Image Asset Studio" to generate notification icons:
   - Right-click on `res` folder → New → Image Asset
   - Select "Notification Icons"
   - Import your white blood drop icon
   - Generate all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)

3. Or manually create these files:
   ```
   android/app/src/main/res/drawable-mdpi/ic_notification.png (24x24px)
   android/app/src/main/res/drawable-hdpi/ic_notification.png (36x36px)
   android/app/src/main/res/drawable-xhdpi/ic_notification.png (48x48px)
   android/app/src/main/res/drawable-xxhdpi/ic_notification.png (72x72px)
   android/app/src/main/res/drawable-xxxhdpi/ic_notification.png (96x96px)
   ```

**Icon Requirements:**
- Must be white on transparent background
- Simple design that works at small sizes (24dp)
- No color (Android system will tint it)
- PNG format with transparency

## Notification Text Improvements

### New Notification Templates (with Emojis)

All notifications now include engaging text with emojis and proper Arabic/English translations:

1. **Blood Request** 🩸
   - EN: "🩸 Blood Donation Needed - Urgent! Donors with blood type {blood_type} are needed in {city}. Your donation can save a life! 💪❤️"
   - AR: "🩸 حاجة ملحّة للتبرع بالدم - عاجل! يُحتاج متبرعين بفصيلة دم {blood_type} في {city}. تبرعك يمكنه إنقاذ حياة! 💪❤️"

2. **Low Stock Alert** 🚨
   - EN: "🚨 Low Blood Stock Alert - Critical shortage! {blood_type} blood stock at {center} is very low. Your help is urgently needed! 🏥⏰"
   - AR: "🚨 تنبيه: انخفاض حاد في المخزون - نقص حرج! مخزون فصيلة {blood_type} في {center} منخفض جداً. نحتاج مساعدتك بشدة! 🏥⏰"

3. **Priority Request** 🔴
   - EN: "🔴 Priority Blood Request - Emergency! {blood_type} blood needed urgently in {city}. Please respond if you can donate! 🆘🙏"
   - AR: "🔴 طلب دم ذو أولوية قصوى - حالة طوارئ! يُحتاج فصيلة {blood_type} بشكل عاجل في {city}. يرجى الاستجابة إذا كنت تستطيع التبرع! 🆘🙏"

4. **Donation Reminder** ✨
   - EN: "✨ You Can Donate Again! - Great news! You are now eligible to donate blood again. Your contribution makes a difference! 🌟❤️"
   - AR: "✨ يمكنك التبرع مجدداً! - أخبار رائعة! أنت الآن مؤهل للتبرع بالدم مرة أخرى. مساهمتك تصنع الفرق! 🌟❤️"

5. **Appointment Confirmed** ✅
   - EN: "✅ Appointment Confirmed - Your donation appointment at {center} is confirmed for {date}. Thank you for being a hero! 🦸‍♂️💉"
   - AR: "✅ تم تأكيد الموعد - تم تأكيد موعد تبرعك بالدم في {center} بتاريخ {date}. شكراً لأنك بطل! 🦸‍♂️💉"

6. **Donation Thanks** 🙏
   - EN: "🙏 Thank You for Donating! - Your blood donation is a gift of life. You've made a real difference in someone's life today! ❤️✨"
   - AR: "🙏 شكراً لتبرعك! - تبرعك بالدم هو هبة الحياة. لقد أحدثت فرقاً حقيقياً في حياة شخص ما اليوم! ❤️✨"

7. **Eligibility Reminder** 📅
   - EN: "📅 Donation Eligibility Update - Only a few days left! You'll be eligible to donate blood again soon. Get ready to save lives! 🩸💪"
   - AR: "📅 تحديث أهلية التبرع - بقيت أيام قليلة فقط! ستكون مؤهلاً للتبرع بالدم مرة أخرى قريباً. استعد لإنقاذ الأرواح! 🩸💪"

## Testing Notifications

### Test on Xiaomi Devices
1. Install app on Xiaomi device
2. Ensure notification permission is granted
3. Trigger a test notification
4. Check that icon appears properly

### Test on Other Chinese Devices (Oppo, Vivo, Huawei)
- Same process as Xiaomi
- Some devices may have additional battery optimization settings that need to be disabled

### General Android Testing
- Test on stock Android (Pixel devices)
- Test on Samsung devices
- Verify emojis display correctly on all devices

## Troubleshooting

### Notifications Not Showing
1. Check notification permission in device settings
2. Ensure FCM token is saved to Supabase profiles table
3. Verify `fcm_token` column exists in profiles table
4. Check battery optimization settings (disable for app)

### Icon Not Showing
1. Verify `ic_notification.xml` exists in `res/drawable`
2. Check AndroidManifest.xml has proper metadata
3. Rebuild app: `flutter clean && flutter build apk`
4. Test on different device brands

### Wrong Language
1. Check user's `language` field in profiles table
2. Default language is Arabic (`ar`) if not set
3. Ensure translations exist in `assets/en.json` and `assets/ar.json`

## Files Modified

1. `lib/core/notifications/notification_templates.dart` - Updated with emojis and better text
2. `lib/features/admin/inventory/data/low_stock_alert_service.dart` - Uses templates now
3. `android/app/src/main/AndroidManifest.xml` - Added notification icon metadata
4. `android/app/src/main/res/drawable/ic_notification.xml` - Notification icon drawable
5. `assets/en.json` & `assets/ar.json` - Updated translations
