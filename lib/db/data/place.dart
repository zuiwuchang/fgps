import 'package:fgps/db/data/gps.dart';
import 'package:sqflite/sqlite_api.dart';

class Place {
  int id;
  String name;
  Place({
    required this.id,
    required this.name,
  });
  Map<String, dynamic> toMap() => <String, dynamic>{
        PlaceHelper.columnID: id,
        PlaceHelper.columnName: name,
      };
  Place.fromMap(Map<String, dynamic> map)
      : id = map[PlaceHelper.columnID],
        name = map[PlaceHelper.columnName];
}

class PlaceHelper {
  static const table = 'place';
  static const columnID = 'id';
  static const columnName = 'name';
  static const columns = [
    columnID,
    columnName,
  ];
  static Future<void> onCreate(DatabaseExecutor db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS 
$table (
$columnID INTEGER PRIMARY KEY AUTOINCREMENT, 
$columnName TEXT DEFAULT ''
)''');
  }

  static Future<void> onUpgrade(
      DatabaseExecutor db, int oldVersion, int newVersion) async {
    await onCreate(db, newVersion);
  }

  PlaceHelper(this.db);
  final Database db;

  Future<int> add(String name) async {
    return db.insert(table, {
      columnName: name,
    });
  }

  Future<Iterable<Place>> list() async {
    final items = await db.query(table);
    return items.map((e) => Place.fromMap(e));
  }

  Future<int> delete(int id) {
    return db.transaction((txn) async {
      final result =
          await txn.delete(table, where: '$columnID = ?', whereArgs: [id]);
      await txn.delete(GPSHelper.table,
          where: '${GPSHelper.columnPlace} = ?', whereArgs: [id]);
      return result;
    });
  }
}
