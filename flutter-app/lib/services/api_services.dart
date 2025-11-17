// lib/services/api_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notes_app/models/note.dart';

class ApiService {
  // change host if your backend runs on emulator/device
  static const String _baseUrl =
      "https://fullstack-notes-app-rf7s.onrender.com/api/notes";

  static Future<List<Note>> fetchNotes() async {
    final res = await http.get(Uri.parse(_baseUrl));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Note.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notes: ${res.statusCode}');
    }
  }

  static Future<Note> createNote(Note note) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toJson()),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Note.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create note: ${res.statusCode}');
    }
  }

  static Future<Note> updateNote(Note note) async {
    if (note.id == null) {
      throw Exception('Note id is required to update');
    }

    final res = await http.put(
      Uri.parse('$_baseUrl/${note.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toJson()),
    );

    if (res.statusCode == 200) {
      return Note.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to update note: ${res.statusCode}');
    }
  }

  static Future<void> deleteNote(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete note: ${res.statusCode}');
    }
  }
}
