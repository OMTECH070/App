import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  // English Strings
  static const Map<String, Map<String, String>> localizedStrings = {
    'en': {
      'app_title': 'AI Smart Farming Assist',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'phone': 'Phone Number',
      'name': 'Full Name',
      'language': 'Language',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'dashboard': 'Dashboard',
      'soil_moisture': 'Soil Moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'water_now': 'Water Now',
      'settings': 'Settings',
      'device_control': 'Device Control',
      'notifications': 'Notifications',
      'automation_mode': 'Automation Mode',
      'manual_mode': 'Manual Mode',
      'connected': 'Connected',
      'offline': 'Offline',
      'last_sync': 'Last Sync',
      'all': 'All',
      'critical': 'Critical',
      'warnings': 'Warnings',
      'language_setting': 'Language',
      'dark_mode': 'Dark Mode',
      'sign_out': 'Sign Out',
      'device_list': 'My Devices',
      'pair_device': 'Pair New Device',
      'device_id': 'Device ID',
      'field_name': 'Field Name',
      'duration': 'Duration (minutes)',
      'start_irrigation': 'Start Irrigation',
      'stop_irrigation': 'Stop All Irrigation',
      'ai_recommendation': 'AI Recommendation',
      'new_recommendation': 'New Recommendation Available',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'unpair_device': 'Unpair Device',
      'are_you_sure': 'Are you sure?',
      'invalid_email': 'Please enter a valid email',
      'password_too_short': 'Password must be at least 8 characters',
      'required_field': 'This field is required',
      'connection_error': 'Connection error. Please check your internet.',
      'offline_mode': 'Offline Mode - Using cached data',
    },
    'hi': {
      'app_title': 'एआई स्मार्ट फार्मिंग असिस्ट',
      'login': 'लॉगिन करें',
      'register': 'रजिस्टर करें',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'phone': 'फोन नंबर',
      'name': 'पूरा नाम',
      'language': 'भाषा',
      'sign_in': 'साइन इन करें',
      'create_account': 'खाता बनाएँ',
      'dont_have_account': 'खाता नहीं है?',
      'already_have_account': 'पहले से खाता है?',
      'dashboard': 'डैशबोर्ड',
      'soil_moisture': 'मिट्टी की नमी',
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'water_now': 'अभी पानी दें',
      'settings': 'सेटिंग्स',
      'device_control': 'डिवाइस नियंत्रण',
      'notifications': 'सूचनाएं',
      'automation_mode': 'स्वचालित मोड',
      'manual_mode': 'मैनुअल मोड',
      'connected': 'जुड़ा हुआ',
      'offline': 'ऑफलाइन',
      'last_sync': 'अंतिम सिंक',
      'all': 'सभी',
      'critical': 'महत्वपूर्ण',
      'warnings': 'चेतावनी',
      'language_setting': 'भाषा',
      'dark_mode': 'डार्क मोड',
      'sign_out': 'साइन आउट करें',
      'device_list': 'मेरे डिवाइस',
      'pair_device': 'नया डिवाइस जोड़ें',
      'device_id': 'डिवाइस आईडी',
      'field_name': 'खेत का नाम',
      'duration': 'अवधि (मिनट)',
      'start_irrigation': 'सिंचाई शुरू करें',
      'stop_irrigation': 'सभी सिंचाई बंद करें',
      'ai_recommendation': 'एआई सिफारिश',
      'new_recommendation': 'नई सिफारिश उपलब्ध है',
      'error': 'त्रुटि',
      'success': 'सफल',
      'loading': 'लोड हो रहा है...',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'confirm': 'पुष्टि करें',
      'delete': 'हटाएं',
      'unpair_device': 'डिवाइस अलग करें',
      'are_you_sure': 'क्या आप सुनिश्चित हैं?',
      'invalid_email': 'कृपया एक वैध ईमेल दर्ज करें',
      'password_too_short': 'पासवर्ड कम से कम 8 वर्ण का होना चाहिए',
      'required_field': 'यह फील्ड आवश्यक है',
      'connection_error': 'कनेक्शन त्रुटि। कृपया अपने इंटरनेट की जांच करें।',
      'offline_mode': 'ऑफलाइन मोड - कैश्ड डेटा का उपयोग कर रहे हैं',
    },
    'mr': {
      'app_title': 'एआই स्मार्ट शेती असिस्ट',
      'login': 'लॉगिन करा',
      'register': 'नोंदणी करा',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'phone': 'फोन क्रमांक',
      'name': 'पूर्ण नाव',
      'language': 'भाषा',
      'sign_in': 'साइन इन करा',
      'create_account': 'खाता तयार करा',
      'dont_have_account': 'खाता नाही आहे?',
      'already_have_account': 'आधीच खाता आहे?',
      'dashboard': 'डॅशबोर्ड',
      'soil_moisture': 'मातीची आर्द्रता',
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'water_now': 'आता पाणी द्या',
      'settings': 'सेटिंग्ज',
      'device_control': 'डिव्हाइस नियंत्रण',
      'notifications': 'सूचना',
      'automation_mode': 'स्वयंचलित मोड',
      'manual_mode': 'व्यक्तिगत मोड',
      'connected': 'जोडले आहे',
      'offline': 'ऑफलाइन',
      'last_sync': 'शेवटचे संक्रमण',
      'all': 'सर्व',
      'critical': 'गंभीर',
      'warnings': 'चेतावणी',
      'language_setting': 'भाषा',
      'dark_mode': 'गडद मोड',
      'sign_out': 'लॉगआउट करा',
      'device_list': 'माझे डिव्हाइस',
      'pair_device': 'नवीन डिव्हाइस जोडा',
      'device_id': 'डिव्हाइस आयडी',
      'field_name': 'शेतामाचे नाव',
      'duration': 'कालावधी (मिनिटे)',
      'start_irrigation': 'सिंचन सुरू करा',
      'stop_irrigation': 'सर्व सिंचन बंद करा',
      'ai_recommendation': 'एआই सुझाव',
      'new_recommendation': 'नवीन सुझाव उपलब्ध आहे',
      'error': 'त्रुटी',
      'success': 'यशस्वी',
      'loading': 'लोड होत आहे...',
      'retry': 'पुन्हा प्रयत्न करा',
      'cancel': 'रद्द करा',
      'confirm': 'खात्री करा',
      'delete': 'हटवा',
      'unpair_device': 'डिव्हाइस जोडणी तोडा',
      'are_you_sure': 'तुम्हाला खात्री आहे?',
      'invalid_email': 'कृपया वैध ईमेल प्रविष्ट करा',
      'password_too_short': 'पासवर्ड किमान 8 वर्णांचा असणे आवश्यक आहे',
      'required_field': 'हे क्षेत्र आवश्यक आहे',
      'connection_error': 'कनेक्शन त्रुटी। कृपया आपले इंटरनेट तपासा।',
      'offline_mode': 'ऑफलाइन मोड - कॅश केलेला डेटा वापरत आहे',
    }
  };

  String translate(String key) {
    final languageCode = locale.languageCode;
    final translations = localizedStrings[languageCode] ?? localizedStrings['en']!;
    return translations[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;
}
