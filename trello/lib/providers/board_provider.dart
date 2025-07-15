import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/board_member.dart';
import '../models/user_role.dart';
import '../utils/database_helper.dart';

class BoardProvider with ChangeNotifier {
  List<Board> _boards = [];
  List<Task> _currentBoardTasks = [];
  List<User> _boardMembers = [];
  List<BoardMember> _boardMembersWithRoles = [];
  Board? _currentBoard;
  UserRole? _currentUserRole;

  List<Board> get boards => _boards;
  List<Task> get currentBoardTasks => _currentBoardTasks;
  List<User> get boardMembers => _boardMembers;
  List<BoardMember> get boardMembersWithRoles => _boardMembersWithRoles;
  Board? get currentBoard => _currentBoard;
  UserRole? get currentUserRole => _currentUserRole;

  // Змінюємо порядок статусів
  List<String> get taskStatuses => ['Заплановано', 'В процесі', 'Ускладнення', 'Готово'];

  bool isOwner(int userId) {
    return _currentBoard?.ownerId == userId;
  }

  bool isManagerOrOwner(int userId) {
    return _currentUserRole == UserRole.owner || _currentUserRole == UserRole.manager;
  }

  bool isTaskCreator(Task task, int userId) {
    return task.createdBy == userId;
  }

  bool canEditTask(Task task, int userId) {
    // Власник і менеджер можуть редагувати всі завдання
    if (isManagerOrOwner(userId)) return true;
    // Звичайний користувач може редагувати тільки свої завдання, непризначені або ті що він створив
    return task.assignedUserId == userId || task.assignedUserId == null || isTaskCreator(task, userId);
  }

  bool canMoveTask(Task task, int userId) {
    // Власник і менеджер можуть переміщувати всі завдання
    if (isManagerOrOwner(userId)) return true;
    // Звичайний користувач може переміщувати тільки свої завдання, непризначені або ті що він створив
    return task.assignedUserId == userId || task.assignedUserId == null || isTaskCreator(task, userId);
  }

  bool canEditTaskDetails(Task task, int userId) {
    // Власник і менеджер можуть редагувати деталі всіх завдань
    if (isManagerOrOwner(userId)) return true;
    // Звичайний користувач може редагувати деталі тільки своїх створених завдань
    return isTaskCreator(task, userId);
  }

  bool canDeleteTask(Task task, int userId) {
    // Власник може видаляти всі завдання
    if (isOwner(userId)) return true;
    // Менеджер може видаляти всі завдання
    if (_currentUserRole == UserRole.manager) return true;
    // Звичайний користувач може видаляти тільки свої створені завдання
    return isTaskCreator(task, userId);
  }

  Future<void> loadBoards(int userId) async {
    try {
      _boards = await DatabaseHelper.instance.getBoardsByUserId(userId);
      notifyListeners();
    } catch (e) {
      print('Load boards error: $e');
    }
  }

  Future<bool> createBoard(String title, String description, int ownerId) async {
    try {
      final board = Board(
        title: title,
        description: description,
        ownerId: ownerId,
        createdAt: DateTime.now(),
      );
      
      await DatabaseHelper.instance.createBoard(board);
      await loadBoards(ownerId);
      return true;
    } catch (e) {
      print('Create board error: $e');
      return false;
    }
  }

  Future<bool> updateBoard(Board board) async {
    try {
      await DatabaseHelper.instance.updateBoard(board);
      _currentBoard = board;
      notifyListeners();
      return true;
    } catch (e) {
      print('Update board error: $e');
      return false;
    }
  }

  Future<void> deleteBoard(int boardId, int userId) async {
    try {
      await DatabaseHelper.instance.deleteBoard(boardId);
      await loadBoards(userId);
    } catch (e) {
      print('Delete board error: $e');
    }
  }

  Future<void> leaveBoard(int boardId, int userId) async {
    try {
      await DatabaseHelper.instance.removeBoardMember(boardId, userId);
      await loadBoards(userId);
    } catch (e) {
      print('Leave board error: $e');
    }
  }

  Future<void> setCurrentBoard(Board board, int userId) async {
    _currentBoard = board;
    _currentUserRole = await DatabaseHelper.instance.getUserRoleInBoard(board.id!, userId);
    await loadBoardTasks(board.id!);
    await loadBoardMembers(board.id!);
    notifyListeners();
  }

  Future<void> loadBoardTasks(int boardId) async {
    try {
      _currentBoardTasks = await DatabaseHelper.instance.getTasksByBoardId(boardId);
      notifyListeners();
    } catch (e) {
      print('Load tasks error: $e');
    }
  }

  Future<void> loadBoardMembers(int boardId) async {
    try {
      _boardMembers = await DatabaseHelper.instance.getBoardMembers(boardId);
      _boardMembersWithRoles = await DatabaseHelper.instance.getBoardMembersWithRoles(boardId);
      notifyListeners();
    } catch (e) {
      print('Load board members error: $e');
    }
  }

  Future<bool> addBoardMember(int userId, UserRole role) async {
    try {
      await DatabaseHelper.instance.addBoardMember(_currentBoard!.id!, userId, role);
      await loadBoardMembers(_currentBoard!.id!);
      return true;
    } catch (e) {
      print('Add board member error: $e');
      return false;
    }
  }

  Future<void> updateMemberRole(int userId, UserRole role) async {
    try {
      await DatabaseHelper.instance.updateBoardMemberRole(_currentBoard!.id!, userId, role);
      await loadBoardMembers(_currentBoard!.id!);
    } catch (e) {
      print('Update member role error: $e');
    }
  }

  Future<void> removeBoardMember(int userId) async {
    try {
      await DatabaseHelper.instance.removeBoardMember(_currentBoard!.id!, userId);
      await loadBoardMembers(_currentBoard!.id!);
    } catch (e) {
      print('Remove board member error: $e');
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    DateTime? deadline,
    required String status,
    required int boardId,
    int? assignedUserId,
    required int createdBy,
  }) async {
    try {
      final task = Task(
        title: title,
        description: description,
        deadline: deadline,
        status: status,
        boardId: boardId,
        assignedUserId: assignedUserId,
        createdBy: createdBy,
        originallyUnassigned: assignedUserId == null,
        createdAt: DateTime.now(),
      );
      
      await DatabaseHelper.instance.createTask(task);
      await loadBoardTasks(boardId);
      return true;
    } catch (e) {
      print('Create task error: $e');
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await DatabaseHelper.instance.updateTask(task);
      await loadBoardTasks(task.boardId);
      return true;
    } catch (e) {
      print('Update task error: $e');
      return false;
    }
  }

  Future<void> updateTaskStatus(Task task, String newStatus, int currentUserId) async {
    try {
      Task updatedTask = task.copyWith(status: newStatus);
      
      // Виправлена автопризначення логіка
      if (task.originallyUnassigned) {
        if (task.assignedUserId == null && newStatus != 'Заплановано') {
          // Якщо завдання вільне і переміщується з "Заплановано" - призначаємо поточному користувачу
          updatedTask = updatedTask.copyWith(assignedUserId: currentUserId);
        } else if (task.assignedUserId == currentUserId && newStatus == 'Заплановано') {
          // Якщо користувач повертає своє автопризначене завдання в "Заплановано" - знімаємо призначення
          updatedTask = updatedTask.copyWith(assignedUserId: null);
        }
      }
      
      await DatabaseHelper.instance.updateTask(updatedTask);
      await loadBoardTasks(task.boardId);
    } catch (e) {
      print('Update task error: $e');
    }
  }

  Future<void> deleteTask(int taskId, int boardId) async {
    try {
      await DatabaseHelper.instance.deleteTask(taskId);
      await loadBoardTasks(boardId);
    } catch (e) {
      print('Delete task error: $e');
    }
  }

  List<Task> getTasksByStatus(String status) {
    return _currentBoardTasks.where((task) => task.status == status).toList();
  }

  List<Task> getTasksByStatusSorted(String status, int currentUserId) {
    final tasks = getTasksByStatus(status);
    
    // Сортуємо: спочатку завдання користувача, потім непризначені, потім чужі
    tasks.sort((a, b) {
      final aIsMyTask = a.assignedUserId == currentUserId;
      final bIsMyTask = b.assignedUserId == currentUserId;
      final aIsUnassigned = a.assignedUserId == null;
      final bIsUnassigned = b.assignedUserId == null;
      
      if (aIsMyTask && !bIsMyTask) return -1;
      if (!aIsMyTask && bIsMyTask) return 1;
      if (aIsUnassigned && !bIsUnassigned && !bIsMyTask) return -1;
      if (!aIsUnassigned && bIsUnassigned && !aIsMyTask) return 1;
      
      return a.createdAt.compareTo(b.createdAt);
    });
    
    return tasks;
  }
}