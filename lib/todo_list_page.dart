import 'package:flutter/material.dart';
import 'package:todoapp/task.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<Task> _taskItems = [];

  void _showModal() {
    String _inputText = '';
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  onChanged: (text) {
                    _inputText = text;
                  },
                ),
              ),
              Center(
                child: RaisedButton(
                  child: Text('登録'),
                  onPressed: () {
                    registerTask(_inputText);
                  },
                ),
              )
            ],
          );
        });
  }

  void registerTask(String text) {
    setState(() {
      _taskItems.add(Task(text, false));
      Navigator.pop(context, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO アプリ'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showModal(),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _taskItems.length,
        itemBuilder: (context, index) {
          final task = _taskItems[index];
          return ListTile(
            leading: Checkbox(
              value: false,
              onChanged: (isChecked) {
                if (isChecked) {
                  setState(() {
                    task.completeTodo();
                  });
                }
              },
            ),
            title: Text(task.text),
          );
        },
      ),
    );
  }
}
