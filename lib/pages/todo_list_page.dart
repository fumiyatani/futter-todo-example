import 'package:flutter/material.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TaskDatabaseHelper databaseHelper = TaskDatabaseHelper.instance;

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
                    register(_inputText);
                  },
                ),
              )
            ],
          );
        });
  }

  FutureBuilder _createFutureBuilder() {
    return FutureBuilder<List<Task>>(
      future: databaseHelper.queryAllTasks(),
      builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
        if (!snapshot.hasData) {
          // snapshot がデータを持っていない場合
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.data == null) {
          // snapshot がジェネリクスで指定したデータを持っていない場合
          return Center(
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
    databaseHelper.registerTask(inputText).then((int) {
      Navigator.pop(context, null);
      _getTasks();
    });
  }

  void deleteTask(String id) {
    databaseHelper.deleteSelectedTask(id).then((i) {
      // 削除後にタスク一覧を取得する。
      _getTasks();
    });
  }

  void _getTasks() {
    setState(() {});
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
      body: _createFutureBuilder(),
    );
  }
}
