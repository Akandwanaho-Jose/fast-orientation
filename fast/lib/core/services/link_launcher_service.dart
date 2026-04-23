import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkLauncherService {
  const LinkLauncherService();

  Future<bool> openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    if (kIsWeb) {
      return launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }

    for (final mode in const [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) {
          return true;
        }
      } catch (error) {
        debugPrint('Failed to launch $uri with $mode: $error');
      }
    }

    return false;
  }
}
