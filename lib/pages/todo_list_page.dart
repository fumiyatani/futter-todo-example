import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todoapp/notification/task_local_notificaiton.dart';
import 'package:todoapp/pages/todo_list_page_presenter.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

const String all = '全て';
const String complete = '完了';
const String incomplete = '未完';

TaskLocalNotificationManager _taskLocalNotificationManager =
    TaskLocalNotificationManager();

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> implements TaskCallback {
  TodoListPresenter _todoListPresenter;

  // どのリストを表示するかを決める。初回は全てから。
  ListType listType = ListType.all;

  @override
  void initState() {
    super.initState();

    _taskLocalNotificationManager.initializeSettings(false);
    _taskLocalNotificationManager.requestIOSPermission();
    _taskLocalNotificationManager.configureSelectNotificationSubject((payload) {
      debugPrint(payload);
    });

    _todoListPresenter = TodoListPresenter(
      taskDatabaseHelper: TaskDatabaseHelper.instance,
      onComplete: this,
    );
  }

  @override
  void onComplete() {
    setState(() {});
  }

  void _showModalWidget({@required String buttonText, Task task}) {
    // taskがnullの場合は登録時に表示しているとみなすため、空の文字列を渡してあげる。
    ValueNotifier<DateTime> selectedDateTime = ValueNotifier(null);
    String editingText = task == null ? '' : task.text;
    TextEditingController textEditingController = TextEditingController(text: editingText);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: textEditingController,
                onChanged: (text) {
                  editingText = text;
                  textEditingController.selection = TextSelection.collapsed(offset: editingText.length);
                },
              ),
            ),
            ValueListenableBuilder<DateTime>(
              valueListenable: selectedDateTime,
              builder: (BuildContext context, selectedDateTime, Widget child) {
                selectedDateTime = selectedDateTime;
                final String formattedDateTime = selectedDateTime == null
                    ? ''
                    : DateFormat('yy/MM/dd').format(selectedDateTime);
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    top: 16.0,
                    right: 24.0,
                  ),
                  child: Text(
                    '期日 : $formattedDateTime',
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 24.0,
              ),
              child: OutlineButton(
                child: const Text('期日を選択'),
                onPressed: () {
                  _showCalendar(context, (dateTime) {
                    selectedDateTime.value = dateTime;
                  });
                },
              ),
            ),
            Center(
              child: RaisedButton(
                  child: Text(buttonText),
                  onPressed: () {
                    if (selectedDateTime != null) {
                      _taskLocalNotificationManager.scheduleNotification(
                          editingText, selectedDateTime.value);
                    }
                    if (task == null) {
                      _todoListPresenter.registerTask(editingText);
                    } else {
                      _todoListPresenter.updateTask(task, editingText);
                    }
                    Navigator.of(context).pop(null);
                  }),
            )
          ],
        );
      },
    );
  }

  void _showCalendar(
      BuildContext context, Function(DateTime) onSelectedDateTime) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    ).then((dateTime) {
      onSelectedDateTime(dateTime);
    });
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
  void dispose() {
    _taskLocalNotificationManager.closeNotificationStream();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _TodoListInheritedWidget(
      tasks: _todoListPresenter.queryTasks(listType),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TODO アプリ'),
          actions: <Widget>[
            _buildMenuButton(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showModalWidget(buttonText: '登録', task: null),
          child: Icon(Icons.add),
        ),
        body: _FutureBuilderTodoListView(
          onPressedRow: (Task task) {
            _showModalWidget(buttonText: '更新', task: task);
          },
          onChecked: (Task task, bool isFinished) {
            _todoListPresenter.updateFinishFlag(task, isFinished);
          },
          onPressedDelete: (String id) {
            _todoListPresenter.deleteTask(id);
          },
        ),
      ),
    );
  }
}

class _FutureBuilderTodoListView extends StatefulWidget {
  _FutureBuilderTodoListView({
    Key key,
    this.onPressedRow,
    this.onChecked,
    this.onPressedDelete,
  }) : super(key: key);

  final Function(Task) onPressedRow;
  final Function(Task, bool) onChecked;
  final Function(String) onPressedDelete;

  @override
  _FutureBuilderTodoListViewState createState() =>
      _FutureBuilderTodoListViewState();
}

// Databaseから取得したデータを表示するためのFutureBuilderで包まれたListView
class _FutureBuilderTodoListViewState
    extends State<_FutureBuilderTodoListView> {
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
        bool isFinished = task.isFinished;
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
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
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => widget.onPressedDelete(task.id),
              ),
              title: _buildText(task.text, isFinished)),
        );
      },
    );
  }

  Text _buildText(String text, bool isFinished) {
    return isFinished
        ? Text(text, style: TextStyle(decoration: TextDecoration.lineThrough))
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
