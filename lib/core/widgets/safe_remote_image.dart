import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class SafeRemoteImage extends StatelessWidget {
  const SafeRemoteImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.assetFallbackPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
  });

  final String? imageUrl;
  final Widget fallback;
  final String? assetFallbackPath;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;

  static bool hasDisplayableSource(String? imageUrl) {
    final trimmed = imageUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return false;
    }

    if (trimmed.startsWith('assets/')) {
      return _isBundledAssetPath(trimmed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'gs';
  }

  static bool _isBundledAssetPath(String path) {
    return path == 'assets/images/MUST.jpg' ||
        path == 'assets/images/MUST_LOGO.png' ||
        path.startsWith('assets/images/home/') ||
        path.startsWith('assets/images/quick_links/');
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _buildFallback();
    }

    if (trimmed.startsWith('assets/')) {
      if (!_isBundledAssetPath(trimmed)) {
        return _buildFallback();
      }
      return Image.asset(
        trimmed,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return _buildFallback();
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return _buildNetworkImage(trimmed);
    }

    if (uri.scheme == 'gs') {
      return FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(trimmed).getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.trim().isNotEmpty) {
            return _buildNetworkImage(snapshot.data!.trim());
          }
          if (snapshot.hasError) {
            return _buildFallback();
          }
          return _buildFallback();
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: (_, __, ___) => _buildFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
    final fallbackAsset = assetFallbackPath?.trim() ?? '';
    if (fallbackAsset.isNotEmpty) {
      return Image.asset(
        fallbackAsset,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return fallback;
  }
}
