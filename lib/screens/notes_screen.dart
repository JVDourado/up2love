// secret_notes_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/note_service.dart';

class SecretNotesScreen extends StatefulWidget {
  final String userUID;

  const SecretNotesScreen({super.key, required this.userUID});

  @override
  State<SecretNotesScreen> createState() => _SecretNotesScreenState();
}

class _SecretNotesScreenState extends State<SecretNotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  late NoteService _noteService;

  @override
  void initState() {
    super.initState();
    _noteService = NoteService(userUID: widget.userUID);
  }

  Future<void> _saveNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) {
      _showSnackBar('Escreva uma nota');
      return;
    }

    try {
      await _noteService.saveNote(noteText);
      _noteController.clear();
      Navigator.pop(context);
      _showSnackBar('Nota salva com sucesso!');
    } catch (e) {
      _showSnackBar('Falha ao salvar nota: $e');
    }
  }

  Future<void> _updateNote(String noteId) async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) {
      _showSnackBar('Escreva uma nota');
      return;
    }

    try {
      await _noteService.updateNote(noteId, noteText);
      _noteController.clear();
      Navigator.pop(context);
      _showSnackBar('Nota atualizada com sucesso!');
    } catch (e) {
      _showSnackBar('Falha ao atualizar nota: $e');
    }
  }

  void _openAddNoteDialog({String? noteId, String? noteText}) {
    _noteController.text = noteText ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(noteId == null ? 'Adicionar Nota' : 'Editar Nota'),
          content: TextField(
            controller: _noteController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Escreva sua nota aqui...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (noteId == null) {
                  await _saveNote();
                } else {
                  await _updateNote(noteId);
                }
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      _showSnackBar('Nota deletada!');
    } catch (e) {
      _showSnackBar('Falha ao deletar nota: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Notas privadas',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compartilhe seus pensamentos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _noteService.getNotesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Sem anotações por enquanto.'),
                        );
                      } else {
                        final notes = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final noteId = notes[index].id;
                            final note = notes[index]['note'];
                            final timestamp = notes[index]['timestamp']?.toDate();
                            final formattedTime = timestamp != null
                                ? DateFormat('yMMMd').add_jm().format(timestamp)
                                : 'Unknown time';

                            return Card(
                              color: Colors.white.withOpacity(0.9),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                title: Text(note,
                                    style: const TextStyle(fontSize: 18)),
                                subtitle: Text(formattedTime,
                                    style: const TextStyle(color: Colors.grey)),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'deletar') {
                                      _deleteNote(noteId);
                                    } else if (value == 'editar') {
                                      _openAddNoteDialog(
                                          noteId: noteId, noteText: note);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                        value: 'deletar',
                                        child: Text('Deletar')),
                                    const PopupMenuItem<String>(
                                        value: 'editar', child: Text('Editar')),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddNoteDialog(),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}