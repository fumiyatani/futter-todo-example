import 'package:flutter/material.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TaskDatabaseHelper _database = TaskDatabaseHelper.instance;

  void registerTask(String taskText) {
    _database.registerTask(taskText).then((int index) {
      setState(() {});
    });
  }

  void deleteTask(String taskId) {
    _database.deleteSelectedTask(taskId).then((int index) {
      setState(() {});
    });
  }

  void updateTask(Task task, String updatedText) {
    _database.updateTaskText(task, updatedText).then((int index) {
      setState(() {});
    });
  }

  void _showModal() {
    String inputText = '';
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
                  inputText = text;
                },
              ),
            ),
            Center(
              child: RaisedButton(
                child: const Text('登録'),
                onPressed: () {
                  registerTask(inputText);
                  Navigator.of(context).pop(null);
                },
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TodoListInheritedWidget(
      tasks: _database.queryAllTasks(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TODO アプリ'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showModal(),
          child: Icon(Icons.add),
        ),
        body: _FutureBuilderTodoListView(),
      ),
    );
  }
}

class _RegisterFloatingActionButton extends StatefulWidget {
  @override
  _RegisterFloatingActionButtonState createState() =>
      _RegisterFloatingActionButtonState();
}

class _RegisterFloatingActionButtonState
    extends State<_RegisterFloatingActionButton> {
  _TodoListPageState inheritedWidget;

  // 登録する際に表示するモーダル
  void _showModal() {
    String inputText = '';
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
                  inputText = text;
                },
              ),
            ),
            Center(
              child: RaisedButton(
                child: const Text('登録'),
                onPressed: () => inheritedWidget.registerTask(inputText),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    inheritedWidget = _TodoListInheritedWidget.of2(context, rebuild: false);
    print('$inheritedWidget');
    return FloatingActionButton(
      onPressed: () => _showModal(),
      child: Icon(Icons.add),
    );
  }
}

class _FutureBuilderTodoListView extends StatefulWidget {
  @override
  _FutureBuilderTodoListViewState createState() =>
      _FutureBuilderTodoListViewState();
}

// Databaseから取得したデータを表示するためのFutureBuilderで包まれたListView
class _FutureBuilderTodoListViewState
    extends State<_FutureBuilderTodoListView> {
  // 更新する際に表示するモーダル
  void _showUpdateModal(_TodoListPageState _todoListPageState, Task task) {
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
                onPressed: () =>
                    _todoListPageState.updateTask(task, updatedText),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _createFutureBuilder(context);
  }

  FutureBuilder<List<Task>> _createFutureBuilder(BuildContext context) {
    Future<List<Task>> tasks =
        _TodoListInheritedWidget.of(context, listen: true).tasks;
    return FutureBuilder<List<Task>>(
      future: tasks,
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
                  onTap: () => _showUpdateModal(
                      _TodoListInheritedWidget.of2(context, rebuild: false),
                      task),
                  leading: Checkbox(
                    value: false,
                    onChanged: (isChecked) {
                      if (isChecked) {
                        _TodoListInheritedWidget.of2(context, rebuild: false)
                            .deleteTask(task.id);
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
}

class _TodoListInheritedWidget extends InheritedWidget {
  // リストに表示するためのタスク一覧
  final Future<List<Task>> tasks;

  _TodoListInheritedWidget({
    Key key,
    @required Widget child,
    this.tasks,
  }) : super(key: key, child: child);

  static _TodoListInheritedWidget of(
    BuildContext context, {
    @required bool listen /* true → 監視対象の場合*/,
  }) {
    return listen
        ? context.dependOnInheritedWidgetOfExactType<_TodoListInheritedWidget>()
        : context
            .getElementForInheritedWidgetOfExactType<_TodoListInheritedWidget>()
            .widget as _TodoListInheritedWidget;
  }

  static _TodoListPageState of2(BuildContext context, {bool rebuild = true}) {
    if (rebuild) {
      return (context.dependOnInheritedWidgetOfExactType(
          aspect: _TodoListPageState) as _TodoListPageState);
    }
    return (context.findAncestorWidgetOfExactType() as _TodoListPageState);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
