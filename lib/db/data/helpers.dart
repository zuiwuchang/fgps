import 'dart:async';

import 'package:fgps/db/data/gps.dart';
import 'package:fgps/db/data/place.dart';
import 'package:flutter/rendering.dart';
import 'package:sqflite/sqflite.dart';

class Helpers {
  Helpers(Database db)
      : place = PlaceHelper(db),
        gps = GPSHelper(db);
  final PlaceHelper place;
  final GPSHelper gps;
  static FutureOr<void> onCreate(Database db, int version) {
    debugPrint('onCreate: $version');
    return db.transaction((txn) async {
      await PlaceHelper.onCreate(txn, version);
      await GPSHelper.onCreate(txn, version);
    });
  }

  static FutureOr<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) {
    debugPrint('onUpgrade: $oldVersion -> $newVersion');
    return db.transaction((txn) async {
      await PlaceHelper.onUpgrade(txn, oldVersion, newVersion);
      await GPSHelper.onUpgrade(txn, oldVersion, newVersion);
    });
  }
}
