import 'package:flutter/cupertino.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:todoapp/task_data/task_database_helper.dart';

class TodoListPresenter {
  TaskDatabaseHelper _taskDatabaseHelper;
  TaskCallback _onComplete;

  TodoListPresenter({@required TaskDatabaseHelper taskDatabaseHelper, @required TaskCallback onComplete}) {
    _taskDatabaseHelper = taskDatabaseHelper;
    _onComplete = onComplete;
  }

  void registerTask(String taskText) {
    if (taskText == null) {
      return;
    }
    _taskDatabaseHelper.registerTask(taskText).then((int index) {
      _onComplete.onComplete();
    });
  }

  void deleteTask(String taskId) {
    _taskDatabaseHelper.deleteSelectedTask(taskId).then((int index) {
      _onComplete.onComplete();
    });
  }

  void updateTask(Task task, String updatedText) {
    if (updatedText == null || task.text == updatedText) {
      return;
    }
    _taskDatabaseHelper.updateTaskText(task, updatedText).then((int index) {
      _onComplete.onComplete();
    });
  }

  void updateFinishFlag(Task task, bool isFinished) {
    _taskDatabaseHelper.updateFinishFlag(task, isFinished).then((int index) {
      _onComplete.onComplete();
    });
  }

  Future<List<Task>> queryTasks(ListType listType) async {
    return _taskDatabaseHelper.queryTasks(listType);
  }
}

class TaskCallback {
  void onComplete() {}
}
