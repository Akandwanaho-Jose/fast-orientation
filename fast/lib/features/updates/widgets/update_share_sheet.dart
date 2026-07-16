import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String fastConnectAppUrl = 'https://fast-must-orientation.web.app';

Future<void> showUpdateShareSheet(
  BuildContext context,
  Announcement announcement,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _UpdateShareSheet(announcement: announcement),
  );
}

String updateShareText(Announcement announcement) {
  return 'Check this update from FAST Connect: ${announcement.title} - '
      '$fastConnectAppUrl';
}

class _UpdateShareSheet extends StatelessWidget {
  const _UpdateShareSheet({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final shareText = updateShareText(announcement);
    final encodedText = Uri.encodeComponent(shareText);
    final encodedUrl = Uri.encodeComponent(fastConnectAppUrl);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [FastBrand.softShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: FastBrand.tintDecoration(FastBrand.primary),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: FastBrand.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Share this update',
                    style: TextStyle(
                      color: FastBrand.headingText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: FastBrand.supportText, height: 1.4),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ShareAction(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF128C7E),
                  onTap:
                      () => _openShareUrl(
                        context,
                        'https://wa.me/?text=$encodedText',
                      ),
                ),
                _ShareAction(
                  icon: Icons.alternate_email_rounded,
                  label: 'X / Twitter',
                  color: const Color(0xFF111827),
                  onTap:
                      () => _openShareUrl(
                        context,
                        'https://twitter.com/intent/tweet?text=$encodedText',
                      ),
                ),
                _ShareAction(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap:
                      () => _openShareUrl(
                        context,
                        'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
                      ),
                ),
                _ShareAction(
                  icon: Icons.link_rounded,
                  label: 'Copy link',
                  color: FastBrand.primary,
                  onTap: () => _copyShareText(context, shareText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openShareUrl(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final opened = await const LinkLauncherService().openUrl(url);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open sharing app.')),
      );
      return;
    }
    navigator.pop();
  }

  Future<void> _copyShareText(BuildContext context, String shareText) async {
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAST Connect update link copied.')),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
