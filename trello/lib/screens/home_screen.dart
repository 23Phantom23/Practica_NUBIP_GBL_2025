import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/board_provider.dart';
import '../widgets/board_card.dart';
import 'board_screen.dart';
import 'create_board_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final boardProvider = Provider.of<BoardProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        boardProvider.loadBoards(userProvider.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мої дошки'),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  child: Text(
                    userProvider.currentUser?.username.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue[800],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text(userProvider.currentUser?.username ?? ''),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Вийти'),
                      ],
                    ),
                    onTap: () {
                      userProvider.logout();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BoardProvider>(
        builder: (context, boardProvider, child) {
          if (boardProvider.boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Немає дошок',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Створіть свою першу дошку!',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Змінюємо на 1 колонку для телефонів, щоб дошки були на всю ширину
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // Зменшуємо висоту для одної колонки
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 2.5,
              ),
              itemCount: boardProvider.boards.length,
              itemBuilder: (context, index) {
                final board = boardProvider.boards[index];
                return Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final isOwner = board.ownerId == userProvider.currentUser!.id!;
                    
                    return BoardCard(
                      board: board,
                      isOwner: isOwner,
                      onTap: () async {
                        await boardProvider.setCurrentBoard(board, userProvider.currentUser!.id!);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BoardScreen(),
                          ),
                        );
                      },
                      onDelete: isOwner ? () => _deleteBoard(board.id!) : null,
                      onLeave: !isOwner ? () => _leaveBoard(board.id!) : null,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBoardDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _showCreateBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateBoardDialog(),
    );
  }

  void _deleteBoard(int boardId) {
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
              boardProvider.deleteBoard(boardId, userProvider.currentUser!.id!);
              Navigator.of(context).pop();
            },
            child: Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _leaveBoard(int boardId) {
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
              boardProvider.leaveBoard(boardId, userProvider.currentUser!.id!);
              Navigator.of(context).pop();
            },
            child: Text('Покинути', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}