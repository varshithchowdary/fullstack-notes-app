// lib/screens/notes_home.dart
import 'package:flutter/material.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/screens/note_detail.dart';
import 'package:notes_app/services/api_services.dart';
import 'package:notes_app/widgets/add_note_form.dart';
import 'package:notes_app/widgets/note_card.dart';
import 'package:notes_app/widgets/view_mode_selector.dart';

enum ViewMode { grid, list, page }

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchNotes();
      setState(() => _notes = data.reversed.toList()); // newest first
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    final newNote = Note(title: title, content: content);

    try {
      final created = await ApiService.createNote(newNote);
      setState(() {
        _notes.insert(0, created);
      });
      titleController.clear();
      contentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showSnack('Failed to add note');
    }
  }

  Future<void> _openNote(Note note, int index) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)),
    );

    if (updated != null) {
      setState(() => _notes[index] = updated);
    }
  }

  void _onDeleteRequest(Note note, int index) {
    final removedNote = note;
    final removedIndex = index;

    setState(() {
      _notes.removeAt(index);
    });

    final snackBar = SnackBar(
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

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((
      reason,
    ) async {
      // Only delete from backend if user did NOT press UNDO
      if (reason != SnackBarClosedReason.action && removedNote.id != null) {
        try {
          await ApiService.deleteNote(removedNote.id!);
        } catch (_) {
          _showSnack('Failed to delete on server');
        }
      }
    });
  }

  void _onLongPress(Note note, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNote(note, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onDeleteRequest(note, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotes),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              // ✅ Comfortable add-note form
              AddNoteForm(
                titleController: titleController,
                contentController: contentController,
                onSubmit: _addNote,
              ),
              const SizedBox(height: 12),

              ViewModeSelector(
                current: _viewMode,
                onChanged: (mode) {
                  setState(() => _viewMode = mode);
                },
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _notes.isEmpty
                    ? const Center(
                        child: Text(
                          "No notes yet 😶\nAdd one above!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : _buildNotesList(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList(ColorScheme cs) {
    switch (_viewMode) {
      case ViewMode.grid:
        return GridView.builder(
          itemCount: _notes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 2,
          ),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _buildDismissible(
              note: note,
              index: index,
              child: NoteCard(
                note: note,
                onTap: () => _openNote(note, index),
                onLongPress: () => _onLongPress(note, index),
              ),
            );
          },
        );

      case ViewMode.list:
        return ListView.builder(
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _buildDismissible(
              note: note,
              index: index,
              child: NoteCard(
                note: note,
                margin: const EdgeInsets.symmetric(vertical: 6),
                onTap: () => _openNote(note, index),
                onLongPress: () => _onLongPress(note, index),
              ),
            );
          },
        );

      case ViewMode.page:
        return PageView.builder(
          itemCount: _notes.length,
          controller: PageController(viewportFraction: 0.85),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _buildDismissible(
              note: note,
              index: index,
              child: NoteCard(
                note: note,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                onTap: () => _openNote(note, index),
                onLongPress: () => _onLongPress(note, index),
              ),
            );
          },
        );
    }
  }

  Widget _buildDismissible({
    required Note note,
    required int index,
    required Widget child,
  }) {
    return Dismissible(
      key: ValueKey(note.id ?? note.title + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _onDeleteRequest(note, index),
      child: child,
    );
  }
}
