import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_role.dart';
import '../widgets/kanban_column.dart';
import 'create_task_dialog.dart';
import 'edit_board_dialog.dart';
import 'manage_members_dialog.dart';

class BoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BoardProvider, UserProvider>(
      builder: (context, boardProvider, userProvider, child) {
        final board = boardProvider.currentBoard!;
        final currentUserId = userProvider.currentUser!.id!;
        final userRole = boardProvider.currentUserRole;
        final isOwner = boardProvider.isOwner(currentUserId);
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(board.title)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(userRole),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole?.displayName ?? 'Гість',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (board.description.isNotEmpty)
                  Text(
                    board.description,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            actions: [
              // Тепер всі користувачі можуть створювати завдання
              IconButton(
                icon: Icon(Icons.add_task),
                onPressed: () => _showCreateTaskDialog(context),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  if (isOwner) ...[
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Редагувати дошку'),
                        ],
                      ),
                      onTap: () => _showEditBoardDialog(context),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 8),
                          Text('Управління учасниками'),
                        ],
                      ),
                      onTap: () => _showManageMembersDialog(context),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Видалити дошку'),
                        ],
                      ),
                      onTap: () => _deleteBoard(context),
                    ),
                  ] else if (userRole == UserRole.manager) ...[
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 8),
                          Text('Управління учасниками'),
                        ],
                      ),
                      onTap: () => _showManageMembersDialog(context),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Покинути дошку'),
                        ],
                      ),
                      onTap: () => _leaveBoard(context),
                    ),
                  ] else ...[
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Покинути дошку'),
                        ],
                      ),
                      onTap: () => _leaveBoard(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: boardProvider.taskStatuses.map((status) {
                return Container(
                  width: 300,
                  margin: EdgeInsets.only(right: 16),
                  child: KanbanColumn(
                    title: status,
                    tasks: boardProvider.getTasksByStatus(status),
                    onTaskMoved: (task, newStatus) {
                      boardProvider.updateTaskStatus(task, newStatus, currentUserId);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Всі користувачі можуть створювати завдання
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateTaskDialog(context),
            child: Icon(Icons.add),
            backgroundColor: Colors.blue[700],
          ),
        );
      },
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return Colors.orange;
      case UserRole.manager:
        return Colors.purple;
      case UserRole.member:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(),
    );
  }

  void _showEditBoardDialog(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => EditBoardDialog(),
      );
    });
  }

  void _showManageMembersDialog(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => ManageMembersDialog(),
      );
    });
  }

  void _deleteBoard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалити дошку?'),
        content: Text('Ця дія незворотна. Всі завдання будуть видалені.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final boardProvider = Provider.of<BoardProvider>(context, listen: false);
              boardProvider.deleteBoard(
                boardProvider.currentBoard!.id!, 
                userProvider.currentUser!.id!
              );
              Navigator.of(context).pop(); // Закрити діалог
              Navigator.of(context).pop(); // Повернутись на головний екран
            },
            child: Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _leaveBoard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Покинути дошку?'),
        content: Text('Ви більше не матимете доступу до цієї дошки.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final boardProvider = Provider.of<BoardProvider>(context, listen: false);
              boardProvider.leaveBoard(
                boardProvider.currentBoard!.id!, 
                userProvider.currentUser!.id!
              );
              Navigator.of(context).pop(); // Закрити діалог
              Navigator.of(context).pop(); // Повернутись на головний екран
            },
            child: Text('Покинути', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}