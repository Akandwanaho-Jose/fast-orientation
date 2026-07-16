import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/updates/widgets/update_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateEngagementSection extends StatefulWidget {
  const UpdateEngagementSection({super.key, required this.announcement});

  final Announcement announcement;

  @override
  State<UpdateEngagementSection> createState() =>
      _UpdateEngagementSectionState();
}

class _UpdateEngagementSectionState extends State<UpdateEngagementSection> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _liked = false;
  bool _submittingComment = false;

  DocumentReference<Map<String, dynamic>> get _updateRef {
    return FirebaseFirestore.instance
        .collection('announcements')
        .doc(widget.announcement.id);
  }

  CollectionReference<Map<String, dynamic>> get _commentsRef {
    return _updateRef.collection('comments');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    HapticFeedback.selectionClick();
    final nextLiked = !_liked;
    setState(() {
      _liked = nextLiked;
    });

    try {
      await _updateRef.set({
        'likeCount': FieldValue.increment(nextLiked ? 1 : -1),
        'lastEngagedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _liked = !nextLiked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the like right now.')),
      );
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    final name = _nameController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty.')));
      _commentFocusNode.requestFocus();
      return;
    }

    setState(() {
      _submittingComment = true;
    });

    try {
      await _commentsRef.add({
        'text': text,
        'name': name.isEmpty ? 'Guest' : name,
        'timestamp': FieldValue.serverTimestamp(),
        'updateId': widget.announcement.id,
      });
      await _updateRef.set({
        'commentCount': FieldValue.increment(1),
        'lastEngagedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _commentController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post the comment. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _updateRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final likeCount = _readCount(data['likeCount']);
        final commentCount = _readCount(data['commentCount']);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(20),
          decoration: FastBrand.surfaceDecoration(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Engage with this update',
                style: TextStyle(
                  color: FastBrand.headingText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'React, comment as a guest, or share it with classmates and visitors.',
                style: TextStyle(color: FastBrand.mutedText, height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _EngagementButton(
                    icon:
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                    label: '$likeCount Likes',
                    selected: _liked,
                    onPressed: _toggleLike,
                  ),
                  _EngagementButton(
                    icon: Icons.mode_comment_outlined,
                    label: '$commentCount Comments',
                    onPressed: () => _commentFocusNode.requestFocus(),
                  ),
                  _EngagementButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    onPressed:
                        () =>
                            showUpdateShareSheet(context, widget.announcement),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _CommentComposer(
                nameController: _nameController,
                commentController: _commentController,
                focusNode: _commentFocusNode,
                submitting: _submittingComment,
                onSubmit: _submitComment,
              ),
              const SizedBox(height: 22),
              _CommentsList(commentsRef: _commentsRef),
            ],
          ),
        );
      },
    );
  }

  int _readCount(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}

class _EngagementButton extends StatelessWidget {
  const _EngagementButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FastBrand.danger : FastBrand.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.22)),
        backgroundColor: color.withValues(alpha: selected ? 0.08 : 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.nameController,
    required this.commentController,
    required this.focusNode,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController commentController;
  final FocusNode focusNode;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: FastBrand.mutedSurfaceDecoration(radius: 20),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Display name (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: commentController,
            focusNode: focusNode,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Write a public comment...',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon:
                  submitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_rounded),
              label: Text(submitting ? 'Posting...' : 'Post Comment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.commentsRef});

  final CollectionReference<Map<String, dynamic>> commentsRef;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          commentsRef
              .orderBy('timestamp', descending: true)
              .limit(20)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: FastBrand.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final comments = snapshot.data?.docs ?? const [];
        if (comments.isEmpty) {
          return const Text(
            'No comments yet. Be the first to add a thought.',
            style: TextStyle(color: FastBrand.mutedText),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Comments',
              style: TextStyle(
                color: FastBrand.headingText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...comments.map((doc) {
              final data = doc.data();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CommentTile(data: data),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = _readString(data['name'], 'Guest');
    final text = _readString(data['text'], '');
    final timestamp = data['timestamp'];
    final date =
        timestamp is Timestamp ? _relativeDate(timestamp.toDate()) : 'Just now';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FastBrand.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: FastBrand.primary.withValues(alpha: 0.10),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: FastBrand.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: FastBrand.headingText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: FastBrand.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: FastBrand.supportText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return 'G';
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  String _relativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
