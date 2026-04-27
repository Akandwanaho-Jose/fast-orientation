import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:flutter/material.dart';

class SafeNetworkAvatar extends StatelessWidget {
  const SafeNetworkAvatar({
    super.key,
    required this.radius,
    this.imageUrl,
    this.backgroundColor = const Color(0xFFEAF1FB),
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackIconColor = Colors.blue,
    this.fallbackIconSize,
    this.fit = BoxFit.cover,
  });

  final double radius;
  final String? imageUrl;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final Color fallbackIconColor;
  final double? fallbackIconSize;
  final BoxFit fit;

  static bool shouldUseNetworkImage(String? imageUrl) {
    return SafeRemoteImage.hasDisplayableSource(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      fallbackIcon,
      size: fallbackIconSize ?? radius,
      color: fallbackIconColor,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: SafeRemoteImage(
            imageUrl: imageUrl,
            fit: fit,
            fallback: Center(child: fallback),
          ),
        ),
      ),
    );
  }
}
