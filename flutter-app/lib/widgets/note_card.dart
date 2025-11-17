// lib/widgets/note_card.dart
import 'package:flutter/material.dart';
import 'package:notes_app/models/note.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.onTap,
    this.onLongPress,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with AutomaticKeepAliveClientMixin {
  bool _highlighted = false;

  @override
  bool get wantKeepAlive => true;

  Color get _baseColor {
    final colors = [
      const Color(0xFFEDE7F6),
      const Color(0xFFF3E5F5),
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
    ];
    final hash = widget.note.title.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: () {
        setState(() => _highlighted = !_highlighted);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _highlighted ? 0.96 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: widget.margin,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _highlighted ? Colors.green.shade200 : _baseColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_highlighted ? 0.18 : 0.1),
                blurRadius: _highlighted ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
            border: _highlighted
                ? Border.all(color: Colors.green.shade700, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.note.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
