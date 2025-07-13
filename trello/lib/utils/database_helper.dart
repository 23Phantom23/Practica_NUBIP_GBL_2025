import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../models/board_member.dart';
import '../models/user_role.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trello_clone.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE boards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        owner_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        status TEXT NOT NULL,
        board_id INTEGER NOT NULL,
        assigned_user_id INTEGER,
        created_by INTEGER NOT NULL,
        originally_unassigned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (board_id) REFERENCES boards (id),
        FOREIGN KEY (assigned_user_id) REFERENCES users (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE board_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        board_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'member',
        added_at TEXT NOT NULL,
        FOREIGN KEY (board_id) REFERENCES boards (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(board_id, user_id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE board_members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          board_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          role TEXT NOT NULL DEFAULT 'member',
          added_at TEXT NOT NULL,
          FOREIGN KEY (board_id) REFERENCES boards (id),
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(board_id, user_id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE board_members ADD COLUMN role TEXT DEFAULT "member"');
      await db.execute('ALTER TABLE tasks ADD COLUMN originally_unassigned INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN created_by INTEGER DEFAULT 1');
    }
  }

  // User operations
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Board operations
  Future<int> createBoard(Board board) async {
    final db = await instance.database;
    return await db.insert('boards', board.toMap());
  }

  Future<List<Board>> getBoardsByUserId(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT b.* FROM boards b
      LEFT JOIN board_members bm ON b.id = bm.board_id
      WHERE b.owner_id = ? OR bm.user_id = ?
      ORDER BY b.created_at DESC
    ''', [userId, userId]);
    
    return List.generate(maps.length, (i) => Board.fromMap(maps[i]));
  }

  Future<void> updateBoard(Board board) async {
    final db = await instance.database;
    await db.update(
      'boards',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  Future<void> deleteBoard(int boardId) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'board_id = ?', whereArgs: [boardId]);
    await db.delete('board_members', where: 'board_id = ?', whereArgs: [boardId]);
    await db.delete('boards', where: 'id = ?', whereArgs: [boardId]);
  }

  // Board members operations
  Future<int> addBoardMember(int boardId, int userId, UserRole role) async {
    final db = await instance.database;
    final member = BoardMember(
      boardId: boardId,
      userId: userId,
      role: role,
      addedAt: DateTime.now(),
    );
    return await db.insert('board_members', member.toMap());
  }

  Future<void> updateBoardMemberRole(int boardId, int userId, UserRole role) async {
    final db = await instance.database;
    await db.update(
      'board_members',
      {'role': role.name},
      where: 'board_id = ? AND user_id = ?',
      whereArgs: [boardId, userId],
    );
  }

  Future<void> removeBoardMember(int boardId, int userId) async {
    final db = await instance.database;
    await db.delete(
      'board_members',
      where: 'board_id = ? AND user_id = ?',
      whereArgs: [boardId, userId],
    );
  }

  Future<List<BoardMember>> getBoardMembersWithRoles(int boardId) async {
    final db = await instance.database;
    final maps = await db.query(
      'board_members',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'added_at',
    );
    
    return List.generate(maps.length, (i) => BoardMember.fromMap(maps[i]));
  }

  Future<List<User>> getBoardMembers(int boardId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN board_members bm ON u.id = bm.user_id
      WHERE bm.board_id = ?
      ORDER BY u.username
    ''', [boardId]);
    
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<UserRole?> getUserRoleInBoard(int boardId, int userId) async {
    final db = await instance.database;
    
    // Спочатку перевіряємо чи є власником
    final ownerQuery = await db.query(
      'boards',
      where: 'id = ? AND owner_id = ?',
      whereArgs: [boardId, userId],
    );
    
    if (ownerQuery.isNotEmpty) {
      return UserRole.owner;
    }
    
    // Потім перевіряємо роль в board_members
    final memberQuery = await db.query(
      'board_members',
      columns: ['role'],
      where: 'board_id = ? AND user_id = ?',
      whereArgs: [boardId, userId],
    );
    
    if (memberQuery.isNotEmpty) {
      final roleString = memberQuery.first['role'] as String;
      return UserRole.values.firstWhere((r) => r.name == roleString);
    }
    
    return null;
  }

  Future<bool> isBoardMember(int boardId, int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'board_members',
      where: 'board_id = ? AND user_id = ?',
      whereArgs: [boardId, userId],
    );
    return maps.isNotEmpty;
  }

  // Task operations
  Future<int> createTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasksByBoardId(int boardId) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}