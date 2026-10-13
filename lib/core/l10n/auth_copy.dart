import 'package:flutter/foundation.dart';
import '../auth/auth_models.dart';

class AuthCopy {
  static final language = ValueNotifier<String>('en');
  static const english = {
    'privacyTitle': 'Privacy lifecycle',
    'exportData': 'View personal data export',
    'currentPassword': 'Current password',
    'requestDeletion': 'Submit deletion request & sign out',
    'cancelDeletion': 'Cancel pending request',
    'refreshStatus': 'Refresh status',
    'profileTitle': 'Profile & privacy',
    'astrologyTitle': 'Optional astrology',
    'saveProfile': 'Save changes',
    'withdrawAstrology': 'Withdraw astrology consent',
    'profileName': 'Display name',
    'profileBio': 'Bio',
    'conflict':
        'This information changed on another device. Reload before saving.',
    'permission':
        'This action requires permission and explicit adult astrology consent.',
    'busy': 'Please wait…',
    'neutral':
        'If your account is eligible, check your email for a code. You may request another later.',
    'policy': 'Use at least 15 characters and no more than 72 UTF-8 bytes.',
    'invalid':
        'Check your email, username and password. Password confirmation must match.',
    'credentials':
        'Sign-in failed. Check your details or use verification and recovery.',
    'validation': 'Check your details or request a new code.',
    'rate': 'Too many attempts. Wait before trying again.',
    'unavailable': 'The service is temporarily unavailable. Try again later.',
    'network':
        'The response could not be confirmed. Check your connection. If refreshing a session, sign in again.',
    'expired': 'Your session ended. Please sign in again.',
    'storage':
        'Secure storage is unavailable. Sign in again after resolving device storage access.',
    'protocol': 'The response could not be confirmed. Please sign in again.',
    'logoutUnconfirmed':
        'Signed out on this device. Server sign-out could not be confirmed.',
    'memory':
        'Browser sessions end on reload. Remember me is available only with device secure storage.',
  };
  static const translations = {
    'bn': {
      'profileTitle': "প্রোফাইল ও গোপনীয়তা",
      'astrologyTitle': "ঐচ্ছিক জ্যোতিষ",
      'saveProfile': "পরিবর্তন সংরক্ষণ করুন",
      'withdrawAstrology': "জ্যোতিষের সম্মতি প্রত্যাহার",
      'profileName': "প্রদর্শিত নাম",
      'profileBio': "পরিচিতি",
      'conflict': "তথ্য অন্য ডিভাইসে বদলেছে। আবার লোড করুন।",
      'rate': "অনেকবার চেষ্টা হয়েছে। অপেক্ষা করুন।",
      'unavailable': "পরিষেবা সাময়িকভাবে অনুপলব্ধ।",
      'validation': "তথ্য যাচাই করুন অথবা নতুন কোড অনুরোধ করুন।",
      'privacyTitle': "গোপনীয়তার ব্যবস্থা",
      'exportData': "ব্যক্তিগত তথ্য দেখুন",
      'currentPassword': "বর্তমান পাসওয়ার্ড",
      'requestDeletion': "মুছে ফেলার অনুরোধ জমা দিন ও সাইন আউট করুন",
      'cancelDeletion': "অপেক্ষমাণ অনুরোধ বাতিল করুন",
      'refreshStatus': "অবস্থা দেখুন",
      'busy': 'অনুগ্রহ করে অপেক্ষা করুন…',
      'expired': 'আপনার সেশন শেষ হয়েছে। আবার সাইন ইন করুন।',
    },
    'hi': {
      'profileTitle': "प्रोफ़ाइल और गोपनीयता",
      'astrologyTitle': "वैकल्पिक ज्योतिष",
      'saveProfile': "बदलाव सहेजें",
      'withdrawAstrology': "ज्योतिष की सहमति वापस लें",
      'profileName': "दिखने वाला नाम",
      'profileBio': "परिचय",
      'conflict': "विवरण दूसरे डिवाइस पर बदले हैं। फिर लोड करें।",
      'rate': "बहुत प्रयास हुए। प्रतीक्षा करें।",
      'unavailable': "सेवा अस्थायी रूप से उपलब्ध नहीं है।",
      'validation': "विवरण जाँचें या नया कोड माँगें।",
      'privacyTitle': "गोपनीयता प्रबंधन",
      'exportData': "व्यक्तिगत डेटा देखें",
      'currentPassword': "वर्तमान पासवर्ड",
      'requestDeletion': "मिटाने का अनुरोध भेजें और साइन आउट करें",
      'cancelDeletion': "लंबित अनुरोध रद्द करें",
      'refreshStatus': "स्थिति देखें",
      'busy': 'कृपया प्रतीक्षा करें…',
      'expired': 'आपका सत्र समाप्त हो गया। फिर से साइन इन करें।',
    },
  };
  static String text(String key, {String? locale}) =>
      translations[locale ?? language.value]?[key] ?? english[key] ?? key;
  static String error(Object error) =>
      text(error is AuthFailure ? error.problem.name : 'protocol');
}
