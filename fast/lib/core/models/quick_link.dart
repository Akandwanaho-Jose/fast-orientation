import 'package:flutter/material.dart';

class QuickLink {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final String? graphicAssetPath;
  final Color color;
  final List<Color> gradientColors;
  final int order;
  final bool enabled;

  const QuickLink({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    this.graphicAssetPath,
    required this.color,
    required this.gradientColors,
    required this.order,
    this.enabled = true,
  });

  QuickLink copyWith({
    String? title,
    String? subtitle,
    String? url,
    String? graphicAssetPath,
    int? order,
    bool? enabled,
  }) {
    return QuickLink(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      url: url ?? this.url,
      icon: icon,
      graphicAssetPath: graphicAssetPath ?? this.graphicAssetPath,
      color: color,
      gradientColors: gradientColors,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
    );
  }
}
