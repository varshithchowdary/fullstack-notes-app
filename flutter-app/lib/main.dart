import 'package:flutter/material.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/services/api_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: "Roboto",
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(14),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: "Roboto",
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(14),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Notes App",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: NotesApp(
        themeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}

enum ViewMode { grid, list, page }

class NotesApp extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const NotesApp({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  List<Note> notes = [];

  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final data = await ApiService.fetchNotes();
    setState(() => notes = data);
  }

  Future<void> addNote() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) return;

    final newNote = Note(
      title: titleController.text,
      content: contentController.text,
    );

    await ApiService.createNote(newNote);

    titleController.clear();
    contentController.clear();
    await loadNotes();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _cycleThemeMode() {
    // Cycle: system → light → dark → system
    ThemeMode next;
    if (widget.themeMode == ThemeMode.system) {
      next = ThemeMode.light;
    } else if (widget.themeMode == ThemeMode.light) {
      next = ThemeMode.dark;
    } else {
      next = ThemeMode.system;
    }
    widget.onThemeModeChanged(next);
  }

  IconData _themeIcon() {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
      default:
        return Icons.brightness_auto;
    }
  }

  String _themeTooltip() {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return "Light mode";
      case ThemeMode.dark:
        return "Dark mode";
      case ThemeMode.system:
      default:
        return "Follow system theme";
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Notes"),
        actions: [
          IconButton(
            tooltip: _themeTooltip(),
            onPressed: _cycleThemeMode,
            icon: Icon(_themeIcon()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // INPUT CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _styledField(controller: titleController, hint: "Title"),
                    const SizedBox(height: 10),
                    _styledField(
                      controller: contentController,
                      hint: "Content",
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: addNote,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Add Note"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // VIEW MODE TOGGLE
              _buildViewModeToggle(cs),

              const SizedBox(height: 12),

              // NOTES SECTION
              Expanded(
                child: notes.isEmpty
                    ? const Center(
                        child: Text(
                          "No notes yet 😶\nAdd one above!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : _buildNotesByViewMode(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: cs.primary,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _buildViewModeToggle(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _viewModeChip(
            icon: Icons.grid_view_rounded,
            label: "Grid",
            mode: ViewMode.grid,
          ),
          _viewModeChip(
            icon: Icons.view_agenda_rounded,
            label: "List",
            mode: ViewMode.list,
          ),
          _viewModeChip(
            icon: Icons.view_carousel_rounded,
            label: "Page",
            mode: ViewMode.page,
          ),
        ],
      ),
    );
  }

  Widget _viewModeChip({
    required IconData icon,
    required String label,
    required ViewMode mode,
  }) {
    final isSelected = _viewMode == mode;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          setState(() => _viewMode = mode);
        },
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

  Widget _buildNotesByViewMode() {
    switch (_viewMode) {
      case ViewMode.grid:
        return GridView.builder(
          itemCount: notes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: (context, index) {
            final note = notes[index];
            return _noteCard(note, margin: EdgeInsets.zero);
          },
        );

      case ViewMode.list:
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _noteCard(
              note,
              margin: const EdgeInsets.symmetric(vertical: 8),
            );
          },
        );

      case ViewMode.page:
        return PageView.builder(
          itemCount: notes.length,
          controller: PageController(viewportFraction: 0.82),
          itemBuilder: (context, index) {
            final note = notes[index];
            return _noteCard(
              note,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            );
          },
        );
    }
  }

  void _showNotePreview(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _noteCard(
    Note note, {
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
  }) {
    bool isSelected = false;

    // Pastel card colors based on title hash
    final pastelColors = [
      const Color(0xFFEDE7F6),
      const Color(0xFFF3E5F5),
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
    ];
    final baseColor =
        pastelColors[note.title.hashCode.abs() % pastelColors.length];

    final heroTag =
        'note_${note.title}_${note.content.hashCode}_${baseColor.value}';

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailPage(note: note, heroTag: heroTag),
              ),
            );
          },
          onDoubleTap: () {
            setStateSB(() {
              isSelected = !isSelected;
            });
          },
          onLongPress: () {
            _showNotePreview(note);
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            scale: isSelected ? 0.96 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: margin,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.shade200 : baseColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.18 : 0.10),
                    blurRadius: isSelected ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: isSelected
                    ? Border.all(color: Colors.green.shade700, width: 2)
                    : null,
              ),
              child: Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          note.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NoteDetailPage extends StatelessWidget {
  final Note note;
  final String heroTag;

  const NoteDetailPage({super.key, required this.note, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Note")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Hero(
          tag: heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      note.content,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
