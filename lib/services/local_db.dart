import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/student.dart';

const _dbName = 'crud_app.db';
const _dbVersion = 1;

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            address TEXT NOT NULL
          );
        ''');
      },
    );

    return _db!;
  }

  Future<List<Student>> getStudents({String? query}) async {
    final db = await _database;
    if (query == null || query.trim().isEmpty) {
      final maps = await db.query('students', orderBy: 'name COLLATE NOCASE');
      return maps.map((m) => Student.fromMap(m)).toList();
    }

    final trimmedQuery = query.trim();
    final isNumeric = int.tryParse(trimmedQuery) != null;

    List<Map<String, dynamic>> maps;
    if (isNumeric) {
      // If query is numeric, search id exactly or name/address with LIKE
      maps = await db.query(
        'students',
        where: 'id = ? OR name LIKE ? OR address LIKE ?',
        whereArgs: [int.parse(trimmedQuery), '%$trimmedQuery%', '%$trimmedQuery%'],
        orderBy: 'name COLLATE NOCASE',
      );
    } else {
      // Otherwise, LIKE search on name and address
      final likeQuery = '%$trimmedQuery%';
      maps = await db.query(
        'students',
        where: 'name LIKE ? OR address LIKE ?',
        whereArgs: [likeQuery, likeQuery],
        orderBy: 'name COLLATE NOCASE',
      );
    }
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<Student> insertStudent(Student student) async {
    final db = await _database;
    final id = await db.insert('students', student.toMap());
    return student.copyWith(id: id);
  }

  Future<int> updateStudent(Student student) async {
    final db = await _database;
    if (student.id == null) return 0;
    return await db.update('students', student.toMap(), where: 'id = ?', whereArgs: [student.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await _database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
