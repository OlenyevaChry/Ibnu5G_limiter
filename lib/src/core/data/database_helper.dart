import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('usage_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE history (
      date TEXT PRIMARY KEY, 
      wifi INTEGER, 
      mobile INTEGER
    )
    ''');
  }

  Future<void> insertOrUpdate(String date, int wifi, int mobile) async {
    final db = await instance.database;

    await db.insert(
      'history',
      {'date': date, 'wifi': wifi, 'mobile': mobile},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await instance.database;
    return await db.query('history', orderBy: 'date DESC');
  }

  // ===============================
  // 🔥 TAMBAHAN: REKAP BULANAN
  // ===============================
  Future<Map<String, int>> getMonthlyUsage(String month) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT 
        SUM(wifi) as totalWifi,
        SUM(mobile) as totalMobile
      FROM history
      WHERE substr(date, 1, 7) = ?
    ''', [month]);

    return {
      "wifi": (result[0]["totalWifi"] as int?) ?? 0,
      "mobile": (result[0]["totalMobile"] as int?) ?? 0,
    };
  }
}