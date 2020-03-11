import 'package:flutter/material.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TaskDatabaseHelper databaseHelper = TaskDatabaseHelper.instance;

  // 登録する際に表示するモーダル
  void _showModal() {
    String _inputText = '';
    showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  onChanged: (String text) {
                    _inputText = text;
                  },
                ),
              ),
              Center(
                child: RaisedButton(
                  child: const Text('登録'),
                  onPressed: () => register(_inputText),
                ),
              )
            ],
          );
        });
  }

  // 更新する際に表示するモーダル
  void _showUpdateModal({@required Task task}) {
    String updatedText = task.text;
    showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: TextEditingController(
                    text: task.text, // Textの初期値を設定
                  ),
                  onChanged: (text) {
                    updatedText = text;
                  },
                ),
              ),
              Center(
                child: RaisedButton(
                  child: const Text('更新'),
                  onPressed: () {
                    updateTask(task, updatedText);
                  },
                ),
              )
            ],
          );
        });
  }

  FutureBuilder<List<Task>> _createFutureBuilder() {
    return FutureBuilder<List<Task>>(
      future: databaseHelper.queryAllTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // snapshot がデータを持っていない場合
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.data == null) {
          // snapshot がジェネリクスで指定したデータを持っていない場合
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final task = snapshot.data[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                child: ListTile(
                  onTap: () => _showUpdateModal(task: task),
                  leading: Checkbox(
                    value: false,
                    onChanged: (isChecked) {
                      if (isChecked) {
                        deleteTask(task.id);
                      }
                    },
                  ),
                  title: Text(task.text),
                ),
              );
            },
          );
        }
      },
    );
  }

  // BottomSheet上の登録ボタンをタップした場合にデータベースに登録する処理。
  void register(String inputText) {
    if (inputText.isEmpty) {
      // テキストが空っぽの場合は登録しない。
      return;
    }
    databaseHelper.registerTask(inputText).then((i) {
      Navigator.pop(context, null);
      _getTasks();
    });
  }

  void deleteTask(String id) {
    databaseHelper.deleteSelectedTask(id).then((i) {
      _getTasks();
    });
  }

  void updateTask(Task task, String updatedText) {
    // ここにDB処理を書く
    if (updatedText == task.text || updatedText.isEmpty) {
      // もし一致していた場合は何もしない。
    } else {
      databaseHelper.updateTaskText(task, updatedText).then((i) {
        Navigator.pop(context, null);
        _getTasks();
      });
    }
  }

  void _getTasks() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO アプリ'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showModal(),
        child: Icon(Icons.add),
      ),
      body: _createFutureBuilder(),
    );
  }
}
