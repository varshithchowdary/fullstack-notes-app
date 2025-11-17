import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/note.dart';

class ApiService {
  static const String baseUrl =
      "https://fullstack-notes-app-rf7s.onrender.com/api/notes";
  // for emulator

  static Future<List<Note>> fetchNotes() async {
    final response = await http.get(Uri.parse(baseUrl));
    print("API RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((e) => Note.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch notes");
    }
  }

  static Future<void> createNote(Note note) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(note.toJson()),
    );
  }
}
