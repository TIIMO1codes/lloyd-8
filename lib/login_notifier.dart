import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_marketing_names/device_marketing_names.dart';

class LoginNotifier {
  static const String _gmailUser = "prowidget09@gmail.com";
  static const String _gmailAppPassword = "mwiy zjoi bcyg jujt";

  /// Get readable Android device name
  static Future<String> _getDeviceName() async {
    if (!Platform.isAndroid) return "Unknown Device";

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;

      final model = android.model;     // e.g. SM-A536E
      final product = android.product; // e.g. a53xq

      // ✅ Correct usage: NO ARGUMENTS
      final marketingName =
          await DeviceMarketingNames().getSingleName();

      if (marketingName.isNotEmpty) {
        return "$marketingName ($product)";
      }

      return "$model ($product)";
    } catch (e) {
      print("Device name error: $e");
      return "Unknown Android Device";
    }
  }

  /// Send login notification email
  static Future<void> sendLoginAlert(String email) async {
    final deviceName = await _getDeviceName();

    final smtpServer = gmail(
      _gmailUser,
      _gmailAppPassword,
    );

    final message = Message()
      ..from = const Address(
        _gmailUser,
        'Security Alert',
      )
      ..recipients.add(email)
      ..subject = 'Login Alert'
      ..text = 'Your account is logged in in $deviceName';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Login alert email failed: $e");
    }
  }
}
