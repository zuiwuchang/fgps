import 'package:sqflite/sqlite_api.dart';

class GPS {
  int id;
  int place;
  String latitude;
  String longitude;
  GPS({
    required this.id,
    required this.place,
    required this.latitude,
    required this.longitude,
  });
  Map<String, dynamic> toMap() => <String, dynamic>{
        GPSHelper.columnID: id,
        GPSHelper.columnPlace: place,
        GPSHelper.columnLatitude: latitude,
        GPSHelper.columnLongitude: longitude,
      };
  GPS.fromMap(Map<String, dynamic> map)
      : id = map[GPSHelper.columnID],
        place = map[GPSHelper.columnPlace],
        latitude = map[GPSHelper.columnLatitude],
        longitude = map[GPSHelper.columnLongitude];
}

class GPSHelper {
  static const table = 'gps';
  static const columnID = 'id';
  static const columnPlace = 'place';
  static const columnLatitude = 'latitude';
  static const columnLongitude = 'longitude';
  static const columns = [
    columnID,
    columnPlace,
    columnLatitude,
    columnLongitude,
  ];

  static Future<void> onCreate(DatabaseExecutor db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS 
$table (
$columnID INTEGER PRIMARY KEY AUTOINCREMENT, 
$columnPlace INTEGER DEFAULT 0,
$columnLatitude TEXT DEFAULT '',
$columnLongitude TEXT DEFAULT ''
)''');

    await db.execute('''CREATE INDEX IF NOT EXISTS 
index_${columnPlace}_of_$table
ON $table ($columnPlace);
''');
  }

  static Future<void> onUpgrade(
      DatabaseExecutor db, int oldVersion, int newVersion) async {
    await onCreate(db, newVersion);
  }

  GPSHelper(this.db);
  final Database db;

  Future<int> add(
    int place,
    String latitude,
    String longitude,
  ) async {
    return db.insert(table, {
      columnPlace: place,
      columnLatitude: latitude,
      columnLongitude: longitude,
    });
  }

  Future<Iterable<GPS>> list(int place) async {
    final items =
        await db.query(table, where: '$columnPlace = ?', whereArgs: [place]);
    return items.map((e) => GPS.fromMap(e));
  }

  Future<int> delete(int id) {
    return db.delete(table, where: '$columnID = ?', whereArgs: [id]);
  }

  Future<int> clear(int place) {
    return db.delete(table, where: '$columnPlace = ?', whereArgs: [place]);
  }
}
