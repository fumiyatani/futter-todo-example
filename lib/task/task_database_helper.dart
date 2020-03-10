import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todoapp/task/task.dart';
import 'package:uuid/uuid.dart';

class TaskDatabaseHelper {
  // データベース名
  static const String _databaseName = "TaskDatabase.db";

  // データベースバージョン
  static const _databaseVersion = 1;

  // テーブル名
  static const String _table = 'task_table';

  // テーブル要素
  static const _columnId = 'id';
  static const _columnText = 'text';
  static const _columnFinishedFlag = 'isFinished';

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
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // テーブルを作成する。
  Future _onCreate(Database db, int version) async {
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
  Future<List<Task>> queryAllTasks() async {
    // テーブルからTaskを全件取得する。
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(_table);

    return List.generate(maps.length, (index) {
      return Task(
        id: maps[index][_columnId],
        text: maps[index][_columnText],
        isFinished: maps[index][_columnFinishedFlag] == 1, // todo bool → int / int →bool を調べる
      );
    });
  }

  // 指定したidのTaskを削除する
  Future deleteSelectedTask(String id) async {
    Database db = await instance.database;
    await db.delete(
      _table,
      where: "$_columnId = ?",
      whereArgs: [id],
    );
  }
}
