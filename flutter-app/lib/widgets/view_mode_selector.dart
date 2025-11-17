// lib/widgets/view_mode_selector.dart
import 'package:flutter/material.dart';
import 'package:notes_app/screens/notes_home.dart';

class ViewModeSelector extends StatelessWidget {
  final ViewMode current;
  final ValueChanged<ViewMode> onChanged;

  const ViewModeSelector({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _chip(
            context,
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            mode: ViewMode.grid,
          ),
          _chip(
            context,
            icon: Icons.view_agenda_rounded,
            label: 'List',
            mode: ViewMode.list,
          ),
          _chip(
            context,
            icon: Icons.view_carousel_rounded,
            label: 'Page',
            mode: ViewMode.page,
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ViewMode mode,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = current == mode;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isSelected
                ? cs.primary.withOpacity(0.12)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
