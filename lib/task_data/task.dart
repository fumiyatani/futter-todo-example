class Task {
  final String id;
  final String text;
  bool isFinished;

  Task({this.id, this.text, this.isFinished});

  Map<String, Object> toMap() {
    return {
      'id' : this.id,
      'text' : this.text,
      'isFinished' : this.isFinished ? 1 : 0
    };
  }
}