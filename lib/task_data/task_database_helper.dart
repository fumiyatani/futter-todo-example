import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todoapp/task_data/task.dart';
import 'package:uuid/uuid.dart';

// 画面に表示するListType
// query のところで使用する。
enum ListType {
  all,
  complete,
  incomplete
}

class TaskDatabaseHelper {
  // データベース名
  static const String _databaseName = "TaskDatabase.db";

  // データベースバージョン
  static const int _databaseVersion = 1;

  // テーブル名
  static const String _table = 'task_table';

  // テーブル要素
  static const String _columnId = 'id';
  static const String _columnText = 'text';
  static const String _columnFinishedFlag = 'isFinished';

  // シングルトン化する
  TaskDatabaseHelper._privateConstructor();

  static final TaskDatabaseHelper instance =
      TaskDatabaseHelper._privateConstructor();

  static Database _database;

  // 実際に使用するのは database を await して Database を取得する
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // データベースの初期化を行う。
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // テーブルを作成する。
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_table (
            $_columnId TEXT PRIMARY KEY,
            $_columnText TEXT NOT NULL,
            $_columnFinishedFlag IINTEGER DEFAULT 0
          )
          ''');
  }

  // 以下テーブルを実際に操作するメソッド
  // 新規タスクを追加する
  Future<int> registerTask(String text) async {
    // 取得したタスクテキストを元にテーブルに登録するためのTaskインスタンスを作成する
    final task = Task(id: Uuid().v4(), text: text, isFinished: false);

    // タスクをテーブルに登録するためにMapに変換する
    // 登録中にコンフリクトが起きた場合は新しく登録するタスクに置き換える
    Database db = await instance.database;
    return await db.insert(
      _table,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // データベースに保存されているタスクを全件取得する
  Future<List<Task>> queryTasks(ListType listType) async {
    // テーブルからTaskを全件取得する。
    Database db = await instance.database;
    List<Map<String, Object>> maps;
    switch (listType) {
      case ListType.all:
        maps = await db.query(_table);
        break;
      case ListType.complete:
        maps = await db.query(_table, where: "$_columnFinishedFlag = ?", whereArgs: <int>[1]);
        break;
      case ListType.incomplete:
        maps = await db.query(_table, where: "$_columnFinishedFlag = ?", whereArgs: <int>[0]);
        break;
    }

    return List.generate(maps.length, (int index) {
      String id = maps[index][_columnId].toString();
      String text = maps[index][_columnText].toString();
      bool isFinished = maps[index][_columnFinishedFlag] == 1;
      return Task(
        id: id,
        text: text,
        isFinished: isFinished,
      );
    });
  }

  // 指定したidのTaskを削除する
  Future<int> deleteSelectedTask(String id) async {
    Database db = await instance.database;
    return await db.delete(
      _table,
      where: "$_columnId = ?",
      whereArgs: <String>[id],
    );
  }

  // タスクテキストの更新処理
  Future<int> updateTaskText(Task task, String updatedText) async {
    Database db = await instance.database;

    Task updatedTask = Task(
      id: task.id,
      text: updatedText,
      isFinished: task.isFinished,
    );

    return await db.update(
      _table,
      updatedTask.toMap(),
      where: "id = ?",
      whereArgs: <String>[task.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // タスクテキストの更新処理
  Future<int> updateFinishFlag(Task task, bool isFinished) async {
    Database db = await instance.database;

    Task updatedTask = Task(
      id: task.id,
      text: task.text,
      isFinished: isFinished,
    );

    return await db.update(
      _table,
      updatedTask.toMap(),
      where: "id = ?",
      whereArgs: <String>[task.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
