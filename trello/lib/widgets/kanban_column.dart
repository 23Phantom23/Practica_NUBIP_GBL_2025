import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/user_provider.dart';
import '../providers/board_provider.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Function(Task, String) onTaskMoved;

  const KanbanColumn({
    Key? key,
    required this.title,
    required this.tasks,
    required this.onTaskMoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, BoardProvider>(
      builder: (context, userProvider, boardProvider, child) {
        final currentUserId = userProvider.currentUser!.id!;
        final sortedTasks = boardProvider.getTasksByStatusSorted(title, currentUserId);
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(title),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sortedTasks.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: DragTarget<Task>(
                    onWillAccept: (task) {
                      if (task == null) return false;
                      return boardProvider.canMoveTask(task, currentUserId);
                    },
                    onAccept: (task) {
                      if (task.status != title) {
                        onTaskMoved(task, title);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty 
                              ? Colors.blue[50] 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: candidateData.isNotEmpty 
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: ListView.builder(
                          itemCount: sortedTasks.length,
                          itemBuilder: (context, index) {
                            final task = sortedTasks[index];
                            final canDrag = boardProvider.canMoveTask(task, currentUserId);
                            
                            if (!canDrag) {
                              return TaskCard(task: task);
                            }
                            
                            return Draggable<Task>(
                              data: task,
                              feedback: Material(
                                elevation: 6,
                                child: Container(
                                  width: 280,
                                  child: TaskCard(task: task),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: TaskCard(task: task),
                              ),
                              child: TaskCard(task: task),
                            );
                          },
                        ),
                      );
                    },
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
}