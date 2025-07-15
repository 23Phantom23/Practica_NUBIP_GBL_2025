import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/user_provider.dart';
import '../providers/board_provider.dart';
import '../screens/edit_task_dialog.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, BoardProvider>(
      builder: (context, userProvider, boardProvider, child) {
        final currentUserId = userProvider.currentUser!.id!;
        final isMyTask = task.assignedUserId == currentUserId;
        final isUnassigned = task.assignedUserId == null;
        final isMyCreatedTask = task.createdBy == currentUserId;
        final isManagerOrOwner = boardProvider.isManagerOrOwner(currentUserId);
        
        // Затемнення для чужих завдань (тільки для звичайних користувачів)
        final opacity = isManagerOrOwner || isMyTask || isUnassigned || isMyCreatedTask ? 1.0 : 0.6;
        
        return Opacity(
          opacity: opacity,
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Кольорова полоска зверху
                Container(
                  height: 6,
                  color: _getStatusColor(task.status),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (boardProvider.canEditTask(task, currentUserId))
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Редагувати'),
                                    ],
                                  ),
                                  onTap: () => _editTask(context),
                                ),
                                if (boardProvider.canDeleteTask(task, currentUserId))
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Видалити'),
                                      ],
                                    ),
                                    onTap: () => _deleteTask(context),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 12),
                      
                      // Показуємо хто створив завдання
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.create, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              'Створив: ${userProvider.getUserById(task.createdBy)?.username ?? 'Невідомо'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      if (task.assignedUserId != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMyTask ? Colors.green[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person, 
                                size: 14, 
                                color: isMyTask ? Colors.green[700] : Colors.blue[700]
                              ),
                              SizedBox(width: 4),
                              Text(
                                userProvider.getUserById(task.assignedUserId!)?.username ?? 'Невідомо',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMyTask ? Colors.green[700] : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (task.assignedUserId == null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                'Вільне завдання',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (task.deadline != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDeadlineColor(task.deadline!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                DateFormat('dd.MM.yyyy').format(task.deadline!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Заплановано':
        return Colors.grey;
      case 'В процесі':
        return Colors.blue;
      case 'Готово':
        return Colors.green;
      case 'Ускладнення':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 1) {
      return Colors.orange;
    } else if (difference <= 3) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  void _editTask(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => EditTaskDialog(task: task),
      );
    });
  }

  void _deleteTask(BuildContext context) {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    boardProvider.deleteTask(task.id!, task.boardId);
  }
}