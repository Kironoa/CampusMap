import 'package:flutter/foundation.dart';
import 'package:naviapp/models/study_note_model.dart';
import 'package:naviapp/repositories/notes_repository.dart';
import 'package:naviapp/core/interfaces.dart';

class NotesServiceBase extends ChangeNotifier implements INotesRepository {
  final NotesRepository _repository;

  List<StudyNote> _notes = [];
  bool _isLoading = false;
  String? _error;

  NotesServiceBase({NotesRepository? repository})
      : _repository = repository ?? NotesRepository();

  List<StudyNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> loadNotes(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _repository.getAll(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<List<StudyNote>> getAll(int userId) => _repository.getAll(userId);

  @override
  Future<StudyNote?> getById(int id) => _repository.getById(id);

  @override
  Future<int> create(StudyNote note) async {
    final id = await _repository.create(0, note);
    await loadNotes(note.userId ?? 0);
    return id;
  }

  @override
  Future<void> update(StudyNote note) async {
    await _repository.update(note);
    await loadNotes(note.userId ?? 0);
  }

  @override
  Future<void> delete(int id) async {
    await _repository.delete(id);
    final note = _notes.firstWhere((n) => n.id == id);
    await loadNotes(note.userId ?? 0);
  }

  @override
  Future<List<StudyNote>> search(int userId, String query) =>
      _repository.search(userId, query);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void addNote(StudyNote note) {
    _notes = [note, ..._notes];
    notifyListeners();
  }

  void updateNoteInList(StudyNote note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      notifyListeners();
    }
  }

  void removeNote(int id) {
    _notes = _notes.where((n) => n.id != id).toList();
    notifyListeners();
  }
}