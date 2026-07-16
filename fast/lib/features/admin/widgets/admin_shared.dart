import 'package:fast/core/services/lib/core/services/CloudinaryService.dart';
import 'package:flutter/material.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:image_picker/image_picker.dart';

class AdminSectionFrame extends StatelessWidget {
  const AdminSectionFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        24,
        compact ? 20 : 24,
        compact ? 44 : 120,
      ),
      children: [
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminSectionTitle(title: title, subtitle: subtitle),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AdminSectionTitle(title: title, subtitle: subtitle),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 16),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          softWrap: true,
          style: TextStyle(
            fontSize: compact ? 28 : 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF152033),
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class AdminOverflowActions extends StatelessWidget {
  const AdminOverflowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.editLabel = 'Edit',
    this.deleteLabel = 'Delete',
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdminAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _AdminAction.edit:
            onEdit();
            break;
          case _AdminAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: _AdminAction.edit,
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(editLabel),
                ],
              ),
            ),
            PopupMenuItem(
              value: _AdminAction.delete,
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(deleteLabel, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
    );
  }
}

enum _AdminAction { edit, delete }

class AdminPrimaryActionButton extends StatelessWidget {
  const AdminPrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.compactLabel,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String? compactLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(compact ? compactLabel ?? label : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: mustBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }
}

class AdminHorizontalScroller extends StatelessWidget {
  const AdminHorizontalScroller({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}

class AdminImageUrlField extends StatefulWidget {
  const AdminImageUrlField({
    super.key,
    required this.controller,
    required this.label,
    this.multiple = false,
  });

  final TextEditingController controller;
  final String label;
  final bool multiple;

  @override
  State<AdminImageUrlField> createState() => _AdminImageUrlFieldState();
}

class AdminImageThumbnail extends StatelessWidget {
  const AdminImageThumbnail({
    super.key,
    this.imageUrl,
    this.icon = Icons.image_rounded,
    this.size = 64,
  });

  final String? imageUrl;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: SafeRemoteImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fallback: Container(
            color: const Color(0xFFEAF1FB),
            child: Icon(icon, color: mustBlue),
          ),
        ),
      ),
    );
  }
}

class _AdminImageUrlFieldState extends State<AdminImageUrlField> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final previewUrl = _firstImageUrl(widget.controller.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            minLines: widget.multiple ? 1 : null,
            maxLines: widget.multiple ? 3 : 1,
            decoration: InputDecoration(
              labelText: widget.label,
              helperText:
                  widget.multiple
                      ? 'Pick images or paste comma separated URLs.'
                      : 'Pick an image or paste an image URL.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon:
                  _uploading
                      ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : IconButton(
                        tooltip:
                            widget.multiple
                                ? 'Pick images from gallery'
                                : 'Pick image from gallery',
                        onPressed: _pickAndUpload,
                        icon: const Icon(Icons.photo_library_rounded),
                      ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (previewUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: SafeRemoteImage(
                  imageUrl: previewUrl,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: const Color(0xFFEAF1FB),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: mustBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    if (_uploading) return;

    try {
      setState(() => _uploading = true);
      final pickedFiles = <XFile>[];
      if (widget.multiple) {
        pickedFiles.addAll(await _picker.pickMultiImage(imageQuality: 85));
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          pickedFiles.add(image);
        }
      }

      if (pickedFiles.isEmpty) {
        return;
      }

      final urls = await _cloudinary.uploadMultipleImages(pickedFiles);
      if (!mounted) return;

      if (widget.multiple) {
        final existing = parseCsv(widget.controller.text);
        widget.controller.text = joinCsv([...existing, ...urls]);
      } else {
        widget.controller.text = urls.first;
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            urls.length == 1
                ? 'Image uploaded successfully.'
                : '${urls.length} images uploaded successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String? _firstImageUrl(String value) {
    final urls = parseCsv(value);
    if (urls.isEmpty) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return urls.first;
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152033),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: mustBlue));
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message,
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 180;

        return AdminCard(
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: compact ? 22 : 24),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 24 : 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF152033),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminTag extends StatelessWidget {
  const AdminTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String? readOptionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

String readString(Map<String, dynamic> data, String key, String fallback) {
  return readOptionalString(data, key) ?? fallback;
}

bool readBool(Map<String, dynamic> data, String key, {bool fallback = false}) {
  final value = data[key];
  return value is bool ? value : fallback;
}

int readInt(Map<String, dynamic> data, String key, {int fallback = 0}) {
  final value = data[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

List<String> parseCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String joinCsv(List<String> values) {
  return values.where((value) => value.trim().isNotEmpty).join(', ');
}

String slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
