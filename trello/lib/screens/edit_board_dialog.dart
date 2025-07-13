import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';

class EditBoardDialog extends StatefulWidget {
  @override
  _EditBoardDialogState createState() => _EditBoardDialogState();
}

class _EditBoardDialogState extends State<EditBoardDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    final board = boardProvider.currentBoard!;
    _titleController.text = board.title;
    _descriptionController.text = board.description;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Редагувати дошку'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Назва дошки',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введіть назву дошки';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Опис',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: _updateBoard,
          child: Text('Зберегти'),
        ),
      ],
    );
  }

  void _updateBoard() async {
    if (!_formKey.currentState!.validate()) return;

    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    final currentBoard = boardProvider.currentBoard!;

    final updatedBoard = currentBoard.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    final success = await boardProvider.updateBoard(updatedBoard);

    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Дошку оновлено!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка оновлення дошки'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}