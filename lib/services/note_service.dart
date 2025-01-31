// note_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteService {
  final String userUID;
  final CollectionReference _notesCollection;

  NoteService({required this.userUID})
      : _notesCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userUID)
            .collection('notes');

  Future<void> saveNote(String noteText) async {
    await _notesCollection.add({
      'note': noteText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNote(String noteId, String noteText) async {
    await _notesCollection.doc(noteId).update({
      'note': noteText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }

  Stream<QuerySnapshot> getNotesStream() {
    return _notesCollection.orderBy('timestamp', descending: true).snapshots();
  }
}