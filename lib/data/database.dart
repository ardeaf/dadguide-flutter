import 'dart:io';

import 'package:dadguide2/data/tables.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Wrapper for database loading and reloading.
class DatabaseHelper {
  // TODO: make this injected
  static final _dbName = 'dadguide.sqlite';
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static var allAwokenSkills = <AwokenSkill>[];

  DadGuideDatabase _database;
  DatabaseHelper._internal();

  // only have a single app-wide reference to the database
  Future<DadGuideDatabase> get database async {
    await ensureDb();
    return _database;
  }

  Future<void> ensureDb() async {
    if (_database != null) {
      return;
    }

    if (!await dbFileExists()) {
      throw 'DB File does not exist';
    }

    Fimber.d('Creating DB');
    _database = new DadGuideDatabase(await _dbFilePath());

    try {
      allAwokenSkills = await MonstersDao(_database).allAwokenSkills();
    } catch (ex) {
      Fimber.e('Failed to get awoken skills from db', ex: ex);
    }
  }

  Future<void> reloadDb() async {
    Fimber.d('Forcing DB Reload');
    _database = null;
    await ensureDb();
    Fimber.d('Reload Complete');
  }

  static Future<bool> dbFileExists() async {
    return FileSystemEntity.typeSync(await _dbFilePath()) == FileSystemEntityType.file;
  }

  static Future<String> _dbFilePath() async {
    return join(await sqflite.getDatabasesPath(), _dbName);
  }
}
