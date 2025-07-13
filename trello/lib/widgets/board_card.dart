import 'package:flutter/material.dart';
import '../models/board.dart';
import 'package:intl/intl.dart';

class BoardCard extends StatelessWidget {
  final Board board;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLeave;

  const BoardCard({
    Key? key,
    required this.board,
    required this.isOwner,
    required this.onTap,
    this.onDelete,
    this.onLeave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      board.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwner)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Власник',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      SizedBox(width: 4),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          if (onDelete != null)
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Видалити'),
                                ],
                              ),
                              onTap: onDelete,
                            ),
                          if (onLeave != null)
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Покинути'),
                                ],
                              ),
                              onTap: onLeave,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (board.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  board.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Spacer(),
              Text(
                'Створено ${DateFormat('dd.MM.yyyy').format(board.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}