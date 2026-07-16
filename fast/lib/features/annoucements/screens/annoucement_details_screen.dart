import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/updates/widgets/update_engagement_section.dart';
import 'package:fast/features/updates/widgets/update_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  const AnnouncementDetailsScreen({super.key, required this.announcement});

  final Announcement announcement;

  @override
  State<AnnouncementDetailsScreen> createState() =>
      _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen>
    with TickerProviderStateMixin {
  final LinkLauncherService _linkLauncherService = const LinkLauncherService();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final PageController _pageController;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? url) async {
    final rawUrl = url?.trim() ?? '';
    if (rawUrl.isEmpty || !await _linkLauncherService.openUrl(rawUrl)) {
      _showSnackBar('Could not open this link.');
    }
  }

  void _shareAnnouncement() {
    HapticFeedback.selectionClick();
    showUpdateShareSheet(context, widget.announcement);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FastBrand.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showImageGallery() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: _currentImageIndex),
                itemCount: widget.announcement.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: SafeRemoteImage(
                      imageUrl: widget.announcement.imageUrls[index],
                      fit: BoxFit.contain,
                      fallback: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 36,
                right: 18,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              if (widget.announcement.imageUrls.length > 1)
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${widget.announcement.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      children: [
                        _buildArticleCard(),
                        UpdateEngagementSection(
                          announcement: widget.announcement,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final hasImages = widget.announcement.hasImages;
    return SliverAppBar(
      expandedHeight: hasImages ? 340 : 190,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: FastBrand.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: FastBrand.primary),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: _shareAnnouncement,
            icon: const Icon(Icons.ios_share_rounded, color: FastBrand.primary),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: hasImages ? _buildImageHero() : _buildGradientHero(),
      ),
    );
  }

  Widget _buildImageHero() {
    final urls = widget.announcement.imageUrls;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: urls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final image = SafeRemoteImage(
              imageUrl: urls[index],
              fit: BoxFit.cover,
              fallback: _buildGradientHero(),
            );
            if (index == 0) {
              return Hero(
                tag: 'announcement-${widget.announcement.id}',
                child: image,
              );
            }
            return image;
          },
        ),
        _HeroScrim(),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: _HeroCaption(
            announcement: widget.announcement,
            onViewGallery: _showImageGallery,
            currentImageIndex: _currentImageIndex,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientHero() {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: FastBrand.heroGradient),
      child: Stack(
        children: [
          const _HeroScrim(),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: _HeroCaption(
              announcement: widget.announcement,
              onViewGallery: null,
              currentImageIndex: _currentImageIndex,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      padding: const EdgeInsets.all(22),
      decoration: FastBrand.surfaceDecoration(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.category_rounded,
                label: widget.announcement.displayCategory,
                color: _categoryColor(widget.announcement.displayCategory),
              ),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: _formatDate(widget.announcement.postedAt),
                color: FastBrand.primary,
              ),
              if (widget.announcement.isPinned)
                const _InfoPill(
                  icon: Icons.push_pin_rounded,
                  label: 'Pinned',
                  color: FastBrand.warning,
                ),
              if (widget.announcement.isUrgent)
                const _InfoPill(
                  icon: Icons.priority_high_rounded,
                  label: 'Urgent',
                  color: FastBrand.danger,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.announcement.title,
            style: const TextStyle(
              color: FastBrand.headingText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: FastBrand.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Published by FAST Connect on ${_formatDetailedDate(widget.announcement.postedAt)}',
                  style: const TextStyle(
                    color: FastBrand.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              color: FastBrand.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.announcement.description,
            style: const TextStyle(
              color: FastBrand.supportText,
              fontSize: 17,
              height: 1.62,
            ),
          ),
          if (widget.announcement.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.announcement.tags
                  .map(
                    (tag) =>
                        _TextPill(label: '#$tag', color: FastBrand.secondary),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (widget.announcement.hasAction)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(widget.announcement.actionUrl),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(widget.announcement.actionLabel ?? 'Read More'),
                ),
              OutlinedButton.icon(
                onPressed: _shareAnnouncement,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share Update'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _DetailsPanel(announcement: widget.announcement),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('event')) {
      return FastBrand.secondary;
    }
    if (normalized.contains('deadline')) {
      return FastBrand.danger;
    }
    if (normalized.contains('research') || normalized.contains('innovation')) {
      return const Color(0xFF5B5FC7);
    }
    if (normalized.contains('opportun')) {
      return FastBrand.warning;
    }
    return FastBrand.primary;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 24) {
      return difference.inHours == 0
          ? '${difference.inMinutes}m ago'
          : '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return _formatDetailedDate(date);
  }

  String _formatDetailedDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.74),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _HeroCaption extends StatelessWidget {
  const _HeroCaption({
    required this.announcement,
    required this.currentImageIndex,
    this.onViewGallery,
  });

  final Announcement announcement;
  final int currentImageIndex;
  final VoidCallback? onViewGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _GlassPill(label: announcement.displayType),
            if (announcement.imageUrls.length > 1 && onViewGallery != null)
              InkWell(
                onTap: onViewGallery,
                borderRadius: BorderRadius.circular(999),
                child: _GlassPill(
                  label:
                      '${currentImageIndex + 1}/${announcement.imageUrls.length} photos',
                  icon: Icons.photo_library_rounded,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          announcement.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: FastBrand.glassPillDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: FastBrand.solidPillDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPill extends StatelessWidget {
  const _TextPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: FastBrand.solidPillDecoration(color, opacity: 0.08),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FastBrand.mutedSurfaceDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: FastBrand.primary),
              SizedBox(width: 8),
              Text(
                'Update Details',
                style: TextStyle(
                  color: FastBrand.headingText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(label: 'Type', value: announcement.displayType),
          _DetailRow(label: 'Category', value: announcement.displayCategory),
          _DetailRow(label: 'Priority', value: announcement.priority),
          const _DetailRow(label: 'Source', value: 'FAST Connect'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: FastBrand.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: FastBrand.supportText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
