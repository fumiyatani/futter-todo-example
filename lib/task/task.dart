
import 'package:uuid/uuid.dart';

class Task {
  final String _id = Uuid().v4();
  final String _text;
  bool _isFinished;

  get id => _id;
  get text => _text;
  get isFinished => _isFinished;

  Task(this._text, this._isFinished);

  void completeTodo() {
    _isFinished = true;
  }
}