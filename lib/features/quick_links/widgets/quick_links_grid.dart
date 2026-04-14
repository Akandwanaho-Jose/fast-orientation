import 'package:fast/core/models/quick_link.dart';
import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/services/quick_links_service.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickLinksGrid extends StatelessWidget {
  const QuickLinksGrid({
    super.key,
    required this.title,
    required this.subtitle,
    this.padding = const EdgeInsets.all(20),
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.1,
  });

  final String title;
  final String subtitle;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final quickLinksService = QuickLinksService();
    const linkLauncherService = LinkLauncherService();

    return StreamBuilder<List<QuickLink>>(
      stream: quickLinksService.watchQuickLinks(),
      builder: (context, snapshot) {
        final links = snapshot.data ?? QuickLinksService.defaultLinks;
        final usingDefaults =
            snapshot.hasError ||
            snapshot.connectionState == ConnectionState.waiting;

        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = _resolveLayout(constraints.maxWidth);

            return Padding(
              padding: padding,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: layout.outerSpacing,
                  vertical: layout.outerSpacing * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(layout.innerSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(usingDefaults),
                      SizedBox(height: layout.innerSpacing),
                      if (links.isEmpty)
                        _buildEmptyState()
                      else
                        GridView.builder(
                          shrinkWrap: shrinkWrap,
                          physics: physics,
                          itemCount: links.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: layout.crossAxisCount,
                            crossAxisSpacing: layout.gridSpacing,
                            mainAxisSpacing: layout.gridSpacing,
                            childAspectRatio: layout.childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            return _buildLinkCard(
                              context,
                              links[index],
                              linkLauncherService,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  _QuickLinksLayout _resolveLayout(double width) {
    if (width >= 1100) {
      return const _QuickLinksLayout(
        crossAxisCount: 4,
        childAspectRatio: 1.02,
        outerSpacing: 24,
        innerSpacing: 20,
        gridSpacing: 14,
      );
    }
    if (width >= 760) {
      return const _QuickLinksLayout(
        crossAxisCount: 3,
        childAspectRatio: 0.98,
        outerSpacing: 20,
        innerSpacing: 18,
        gridSpacing: 12,
      );
    }
    if (width >= 360) {
      final resolvedAspectRatio =
          childAspectRatio < 0.92
              ? 0.92
              : (childAspectRatio > 1.22 ? 1.22 : childAspectRatio);
      return _QuickLinksLayout(
        crossAxisCount: crossAxisCount,
        childAspectRatio: resolvedAspectRatio,
        outerSpacing: 14,
        innerSpacing: 14,
        gridSpacing: 12,
      );
    }
    return const _QuickLinksLayout(
      crossAxisCount: 1,
      childAspectRatio: 2.2,
      outerSpacing: 10,
      innerSpacing: 12,
      gridSpacing: 10,
    );
  }

  Widget _buildHeader(bool usingDefaults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [mustBlue, mustGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: mustBlue,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (usingDefaults) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: mustBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: mustBlue.withOpacity(0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: mustBlue.withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Using built-in links. Firestore overrides in '
                    '"${QuickLinksService.collectionName}" '
                    'will update these without an app release.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off_rounded, color: Colors.grey[300], size: 36),
          const SizedBox(height: 10),
          Text(
            'No quick links available right now.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    QuickLink link,
    LinkLauncherService linkLauncherService,
  ) {
    return Semantics(
      label: link.title,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openLink(context, link, linkLauncherService),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: link.gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: link.color.withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                final h = cardConstraints.maxHeight;
                final w = cardConstraints.maxWidth;
                final narrow = w < 170;
                final compact = h < 180 || narrow;
                final spacious = h >= 225 && w >= 185;
                final double pad = compact ? 12 : (spacious ? 18 : 15);
                final double graphicFrameSize =
                    compact ? 66 : (spacious ? 92 : 78);
                final double graphicSize = compact ? 36 : (spacious ? 52 : 44);
                final double titleSize =
                    compact ? 10.8 : (spacious ? 15.2 : 13.2);
                final double subtitleSize = compact ? 9.6 : 10.8;
                final bool showSubtitle = h >= 166;
                final bool showOpen = h >= 110;

                return SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -w * 0.20,
                        right: -w * 0.06,
                        child: Container(
                          width: w * 0.62,
                          height: w * 0.62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                      ),
                      Positioned(
                        top: h * 0.24,
                        left: -w * 0.18,
                        child: Container(
                          width: w * 0.46,
                          height: w * 0.46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -w * 0.22,
                        right: -w * 0.08,
                        child: Container(
                          width: w * 0.44,
                          height: w * 0.44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.10),
                                Colors.transparent,
                                Colors.black.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!compact)
                        Positioned(
                          top: pad,
                          right: pad,
                          child: _buildTopBadge(compact: compact),
                        ),
                      Padding(
                        padding: EdgeInsets.all(pad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: _buildGraphicFrame(
                                link: link,
                                frameSize: graphicFrameSize,
                                graphicSize: graphicSize,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              link.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: titleSize,
                                height: 1.02,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.25,
                              ),
                            ),
                            if (showSubtitle) ...[
                              SizedBox(height: compact ? 4 : 6),
                              Text(
                                link.subtitle,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w500,
                                  height: 1.22,
                                ),
                              ),
                            ],
                            if (showOpen) ...[
                              SizedBox(height: compact ? 7 : 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 8 : 10,
                                  vertical: compact ? 5 : 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Open',
                                      style: TextStyle(
                                        fontSize: compact ? 9.4 : 10.5,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: compact ? 4 : 5),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      color: Colors.white,
                                      size: compact ? 11 : 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphicFrame({
    required QuickLink link,
    required double frameSize,
    required double graphicSize,
  }) {
    return Container(
      width: frameSize,
      height: frameSize,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(18),
        ),
        child: _buildLinkGraphic(link, graphicSize),
      ),
    );
  }

  Widget _buildTopBadge({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 10 : 11,
            color: Colors.white,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            'Official',
            style: TextStyle(
              fontSize: compact ? 8.8 : 9.2,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkGraphic(QuickLink link, double graphicSize) {
    final assetPath = link.graphicAssetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(graphicSize * 0.10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(link.icon, color: link.color, size: graphicSize),
        ),
      );
    }

    return Icon(link.icon, color: link.color, size: graphicSize);
  }

  Future<void> _openLink(
    BuildContext context,
    QuickLink link,
    LinkLauncherService linkLauncherService,
  ) async {
    HapticFeedback.lightImpact();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Opening ${link.title}...'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final opened = await linkLauncherService.openUrl(link.url);

    if (!context.mounted) return;

    if (!opened) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Could not open ${link.title}. Please try again.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class _QuickLinksLayout {
  const _QuickLinksLayout({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.outerSpacing,
    required this.innerSpacing,
    required this.gridSpacing,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final double outerSpacing;
  final double innerSpacing;
  final double gridSpacing;
}
