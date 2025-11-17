// lib/main.dart
import 'package:flutter/material.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/services/api_services.dart';

void main() {
  runApp(const NotesAppRoot());
}

class NotesAppRoot extends StatelessWidget {
  const NotesAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFF59E0B), // warm gold
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF22C55E), // neon-ish green
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Notebook',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF020617),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const NotesHomePage(),
    );
  }
}

enum ViewMode { list, grid, carousel }

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  bool _loading = false;
  String? _error;
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchNotes();
      setState(() {
        // newest first
        _notes = data.reversed.toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Note? note, int? index}) async {
    final result = await Navigator.push<Note>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => NoteEditorPage(note: note),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );

    if (result == null) return;

    setState(() {
      if (note == null) {
        // created
        _notes.insert(0, result);
      } else if (index != null) {
        _notes[index] = result;
      }
    });
  }

  void _deleteNote(Note note, int index) {
    final removedNote = note;
    final removedIndex = index;

    setState(() {
      _notes.removeAt(index);
    });

    final snack = SnackBar(
      content: const Text('Note deleted'),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          setState(() {
            _notes.insert(removedIndex, removedNote);
          });
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snack).closed.then((
      reason,
    ) async {
      if (reason != SnackBarClosedReason.action && removedNote.id != null) {
        try {
          await ApiService.deleteNote(removedNote.id!);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete on server')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Notes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _ViewModeToggle(
              current: _viewMode,
              onChanged: (mode) {
                setState(() => _viewMode = mode);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotes,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildBody(cs, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
      // custom bottom "add note" bar instead of a boring +
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 12,
            top: 4,
          ),
          child: GestureDetector(
            onTap: () => _openEditor(),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark
                    ? const Color(0xFF111827)
                    : const Color(0xFFFFFBEB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: cs.primary.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // folded paper + pencil vibe
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: cs.primary.withOpacity(0.12),
                        ),
                      ),
                      Icon(Icons.edit_rounded, color: cs.primary, size: 20),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Write a new note...',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? Colors.white.withOpacity(0.85)
                          : Colors.black.withOpacity(0.65),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: cs.primary.withOpacity(0.85),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    if (_notes.isEmpty) {
      return const Center(
        child: Text(
          'No notes yet.\nUse the bar below to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    switch (_viewMode) {
      case ViewMode.list:
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _wrapWithDismissible(
              note: note,
              index: index,
              child: NotebookCard(
                note: note,
                mode: CardMode.list,
                onTap: () => _openEditor(note: note, index: index),
              ),
            );
          },
        );

      case ViewMode.grid:
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _notes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _wrapWithDismissible(
              note: note,
              index: index,
              child: NotebookCard(
                note: note,
                mode: CardMode.grid,
                onTap: () => _openEditor(note: note, index: index),
              ),
            );
          },
        );

      case ViewMode.carousel:
        return PageView.builder(
          controller: PageController(viewportFraction: 0.85),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: NotebookCard(
                note: note,
                mode: CardMode.carousel,
                onTap: () => _openEditor(note: note, index: index),
              ),
            );
          },
        );
    }
  }

  Widget _wrapWithDismissible({
    required Note note,
    required int index,
    required Widget child,
  }) {
    return Dismissible(
      key: ValueKey('${note.id}-${note.title}-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNote(note, index),
      child: child,
    );
  }
}

/// Toggle row for list / grid / carousel
class _ViewModeToggle extends StatelessWidget {
  final ViewMode current;
  final ValueChanged<ViewMode> onChanged;

  const _ViewModeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF020617)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            _chip(
              context,
              icon: Icons.view_agenda_rounded,
              label: 'List',
              mode: ViewMode.list,
            ),
            _chip(
              context,
              icon: Icons.grid_view_rounded,
              label: 'Grid',
              mode: ViewMode.grid,
            ),
            _chip(
              context,
              icon: Icons.view_carousel_rounded,
              label: 'Flip',
              mode: ViewMode.carousel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ViewMode mode,
  }) {
    final isSelected = mode == current;
    final cs = Theme.of(context).colorScheme;

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
                color: isSelected
                    ? cs.primary
                    : cs.onSurfaceVariant.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- NOTEBOOK CARD ----------

enum CardMode { list, grid, carousel }

class NotebookCard extends StatelessWidget {
  final Note note;
  final CardMode mode;
  final VoidCallback? onTap;

  const NotebookCard({
    super.key,
    required this.note,
    required this.mode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double height;
    switch (mode) {
      case CardMode.list:
        height = 110;
        break;
      case CardMode.grid:
        height = 120;
        break;
      case CardMode.carousel:
        height = 150;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            // notebook "spine" strip
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF020617)
                      : const Color(0xFFFFFEFB),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                  ],
                  border: Border.all(color: cs.primary.withOpacity(0.10)),
                ),
                child: Stack(
                  children: [
                    // folded corner hint
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CustomPaint(
                        size: const Size(24, 24),
                        painter: _CornerFoldPainter(
                          color: isDark
                              ? const Color(0xFF111827)
                              : const Color(0xFFFFF7E6),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (note.title.trim().isNotEmpty) ...[
                            Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            note.content,
                            maxLines: mode == CardMode.carousel ? 4 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the folded paper corner effect
class _CornerFoldPainter extends CustomPainter {
  final Color color;

  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerFoldPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------- EDITOR PAGE ----------

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);

    try {
      late Note saved;
      if (_isEditing) {
        final toUpdate = widget.note!.copyWith(title: title, content: content);
        saved = await ApiService.updateNote(toUpdate);
      } else {
        final toCreate = Note(title: title, content: content);
        saved = await ApiService.createNote(toCreate);
      }

      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save note')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit note' : 'New note'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start writing your thoughts...',
                  border: InputBorder.none,
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF3F4F6),
    );
  }
}
