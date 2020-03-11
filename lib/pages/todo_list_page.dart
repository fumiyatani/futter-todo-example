import 'package:flutter/material.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

const String all = '全て';
const String complete = '完了';
const String incomplete = '未完';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TaskDatabaseHelper _database = TaskDatabaseHelper.instance;

  // どのリストを表示するかを決める。初回は全てから。
  ListType listType = ListType.all;

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

  void updateFinishFlag(Task task, bool isFinished) {
    _database.updateFinishFlag(task, isFinished).then((int index) {
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

  void _showUpdateModal(Task task) {
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
                    Navigator.of(context).pop(null);
                  }),
            )
          ],
        );
      },
    );
  }

  PopupMenuButton _buildMenuButton() {
    return PopupMenuButton<String>(
      // タップされたものをものを調べて、rebuildする。
      onSelected: (value) {
        switch (value) {
          case all:
            setState(() {
              listType = ListType.all;
            });
            break;
          case complete:
            listType = ListType.complete;
            break;
          case incomplete:
            listType = ListType.incomplete;
        }
        setState(() {});
      },
      icon: Icon(Icons.sort),
      itemBuilder: (BuildContext context) {
        return List.generate(3, (int index) {
          String title;
          switch (index) {
            case 0:
              title = all;
              break;
            case 1:
              title = complete;
              break;
            case 2:
              title = incomplete;
          }
          return PopupMenuItem(
            child: Text(title),
            value: title,
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TodoListInheritedWidget(
      tasks: _database.queryTasks(listType),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TODO アプリ'),
          actions: <Widget>[
            _buildMenuButton(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showModal(),
          child: Icon(Icons.add),
        ),
        body: _FutureBuilderTodoListView(
          onPressedRow: (Task task) {
            _showUpdateModal(task);
          },
          onChecked: (Task task, bool isFinished) {
            updateFinishFlag(task, isFinished);
          },
        ),
      ),
    );
  }
}

class _FutureBuilderTodoListView extends StatefulWidget {
  _FutureBuilderTodoListView({Key key, this.onPressedRow, this.onChecked})
      : super(key: key);

  final Function(Task) onPressedRow;
  final Function(Task, bool) onChecked;

  @override
  _FutureBuilderTodoListViewState createState() =>
      _FutureBuilderTodoListViewState();
}

// Databaseから取得したデータを表示するためのFutureBuilderで包まれたListView
class _FutureBuilderTodoListViewState
    extends State<_FutureBuilderTodoListView> {
  // タスクを完了したかどうかのフラグ。
  bool isFinished = false;

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
          return _buildListView(snapshot.data);
        }
      },
    );
  }

  ListView _buildListView(List<Task> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final task = data[index];
        isFinished = task.isFinished;
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black12),
            ),
          ),
          child: ListTile(
              onTap: () {
                widget.onPressedRow(task);
              },
              leading: Checkbox(
                value: isFinished,
                onChanged: (isChecked) {
                  widget.onChecked(task, isChecked);
                  setState(() {
                    isFinished = isChecked;
                  });
                },
              ),
              title: _buildText(task.text, isFinished)),
        );
      },
    );
  }

  Text _buildText(String text, bool isFinished) {
    return isFinished
        ? Text(
            text,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
            ),
          )
        : Text(text);
  }

  @override
  Widget build(BuildContext context) {
    return _createFutureBuilder(context);
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
    @required bool listen /* 監視対象の場合 → true */,
  }) {
    return listen
        ? context.dependOnInheritedWidgetOfExactType<_TodoListInheritedWidget>()
        : context
            .getElementForInheritedWidgetOfExactType<_TodoListInheritedWidget>()
            .widget as _TodoListInheritedWidget;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
