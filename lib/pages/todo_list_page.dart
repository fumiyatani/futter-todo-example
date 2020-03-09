import 'package:flutter/material.dart';
import 'package:todoapp/task/task.dart';
import 'package:todoapp/task/task_database_helper.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TaskDatabaseHelper databaseHelper = TaskDatabaseHelper.instance;

  // データベースから取得した値を保持しておく。
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
                    register(_inputText);
                  },
                ),
              )
            ],
          );
        });
  }

  // BottomSheet上の登録ボタンをタップした場合にデータベースに登録する処理。
  void register(String inputText) async {
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
  
  void _getTasks() async {
    int itemCount = _taskItems.length;
    if (itemCount > 0) {
      // リスト内に配列が1つでもある場合は一度全てを削除する
      _taskItems.clear();
    }
    await databaseHelper.queryAllTasks().then((tasks) {
      setState(() {
        _taskItems.addAll(tasks);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    databaseHelper.queryAllTasks().then((tasks) {
      setState(() {
        _taskItems.addAll(tasks);
      });
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
          return ListTile( // todo 削除時、追加時はアニメーションを行うようにする。
            leading: Checkbox(
              value: false,
              onChanged: (isChecked) {
                if (isChecked) {
                  deleteTask(_taskItems[index].id);
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
