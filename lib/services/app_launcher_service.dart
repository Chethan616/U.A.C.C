import 'package:url_launcher/url_launcher.dart';

/// Service for launching external apps and performing actions
class AppLauncherService {
  static final AppLauncherService _instance = AppLauncherService._internal();
  factory AppLauncherService() => _instance;
  AppLauncherService._internal();

  /// Launch an app by package name or app name
  Future<bool> launchApp(String appName) async {
    try {
      final packageName = _getPackageName(appName);

      // Try to launch with package name first
      if (packageName != null) {
        final uri = Uri.parse('package:$packageName');
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Fallback to app-specific URIs
      final appUri = _getAppUri(appName);
      if (appUri != null) {
        final uri = Uri.parse(appUri);
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      return false;
    } catch (e) {
      print('Error launching app $appName: $e');
      return false;
    }
  }

  /// Launch phone dialer with number
  Future<bool> launchPhone(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching phone: $e');
      return false;
    }
  }

  /// Launch SMS with number and optional message
  Future<bool> launchSMS(String phoneNumber, [String? message]) async {
    try {
      String smsUri = 'sms:$phoneNumber';
      if (message != null && message.isNotEmpty) {
        smsUri += '?body=${Uri.encodeComponent(message)}';
      }
      final uri = Uri.parse(smsUri);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching SMS: $e');
      return false;
    }
  }

  /// Launch email with recipient and optional subject/body
  Future<bool> launchEmail(String email,
      [String? subject, String? body]) async {
    try {
      String emailUri = 'mailto:$email';
      List<String> params = [];

      if (subject != null && subject.isNotEmpty) {
        params.add('subject=${Uri.encodeComponent(subject)}');
      }
      if (body != null && body.isNotEmpty) {
        params.add('body=${Uri.encodeComponent(body)}');
      }

      if (params.isNotEmpty) {
        emailUri += '?${params.join('&')}';
      }

      final uri = Uri.parse(emailUri);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching email: $e');
      return false;
    }
  }

  /// Launch web URL
  Future<bool> launchWeb(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching web URL: $e');
      return false;
    }
  }

  /// Get package name for common apps
  String? _getPackageName(String appName) {
    final appLower = appName.toLowerCase().trim();

    final packageMap = <String, String>{
      // Social Media
      'whatsapp': 'com.whatsapp',
      'instagram': 'com.instagram.android',
      'facebook': 'com.facebook.katana',
      'twitter': 'com.twitter.android',
      'telegram': 'org.telegram.messenger',
      'snapchat': 'com.snapchat.android',
      'linkedin': 'com.linkedin.android',

      // Payment Apps
      'gpay': 'com.google.android.apps.nbu.paisa.user',
      'google pay': 'com.google.android.apps.nbu.paisa.user',
      'phonepe': 'com.phonepe.app',
      'phone pe': 'com.phonepe.app',
      'paytm': 'net.one97.paytm',
      'bhim': 'in.org.npci.upiapp',
      'amazon pay': 'in.amazon.mShop.android.shopping',

      // Banking Apps
      'sbi': 'com.sbi.SBIFreedomPlus',
      'hdfc': 'com.snapwork.hdfc',
      'icici': 'com.csam.icici.bank.imobile',
      'axis': 'com.axis.mobile',
      'kotak': 'com.msf.kbank.mobile',

      // Email & Productivity
      'gmail': 'com.google.android.gm',
      'outlook': 'com.microsoft.office.outlook',
      'microsoft teams': 'com.microsoft.teams',
      'zoom': 'us.zoom.videomeetings',
      'google meet': 'com.google.android.apps.meetings',

      // Shopping & Food
      'amazon': 'in.amazon.mShop.android.shopping',
      'flipkart': 'com.flipkart.android',
      'myntra': 'com.myntra.android',
      'zomato': 'com.application.zomato',
      'swiggy': 'in.swiggy.android',
      'uber': 'com.ubercab',
      'ola': 'com.olacabs.customer',

      // Entertainment
      'youtube': 'com.google.android.youtube',
      'netflix': 'com.netflix.mediaclient',
      'spotify': 'com.spotify.music',
      'prime video': 'com.amazon.avod.thirdpartyclient',
      'disney hotstar': 'in.startv.hotstar',
      'jio cinema': 'com.jio.media.jiobeats',

      // Others
      'google maps': 'com.google.android.apps.maps',
      'uber eats': 'com.ubercab.eats',
      'truecaller': 'com.truecaller',
    };

    // Direct match
    if (packageMap.containsKey(appLower)) {
      return packageMap[appLower];
    }

    // Partial match
    for (final entry in packageMap.entries) {
      if (appLower.contains(entry.key) || entry.key.contains(appLower)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get app-specific URI schemes
  String? _getAppUri(String appName) {
    final appLower = appName.toLowerCase().trim();

    final uriMap = <String, String>{
      'whatsapp': 'whatsapp://',
      'instagram': 'instagram://',
      'facebook': 'fb://',
      'twitter': 'twitter://',
      'telegram': 'tg://',
      'youtube': 'youtube://',
      'spotify': 'spotify://',
      'maps': 'geo:0,0?q=location',
      'google maps': 'geo:0,0?q=location',
    };

    return uriMap[appLower];
  }

  /// Check if app is installed
  Future<bool> isAppInstalled(String appName) async {
    try {
      final packageName = _getPackageName(appName);
      if (packageName != null) {
        final uri = Uri.parse('package:$packageName');
        return await canLaunchUrl(uri);
      }

      final appUri = _getAppUri(appName);
      if (appUri != null) {
        final uri = Uri.parse(appUri);
        return await canLaunchUrl(uri);
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
