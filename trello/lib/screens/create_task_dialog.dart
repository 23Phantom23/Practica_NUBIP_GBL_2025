import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';

class CreateTaskDialog extends StatefulWidget {
  @override
  _CreateTaskDialogState createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDeadline;
  String _selectedStatus = 'Заплановано';
  int? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Створити завдання'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Назва завдання',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введіть назву завдання';
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
              SizedBox(height: 16),
              Consumer<BoardProvider>(
                builder: (context, boardProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                    ),
                    items: boardProvider.taskStatuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              Consumer2<UserProvider, BoardProvider>(
                builder: (context, userProvider, boardProvider, child) {
                  // Показуємо тільки власника та учасників дошки
                  final availableUsers = [
                    userProvider.getUserById(boardProvider.currentBoard!.ownerId)!,
                    ...boardProvider.boardMembers,
                  ];

                  return DropdownButtonFormField<int?>(
                    value: _selectedUserId,
                    decoration: InputDecoration(
                      labelText: 'Призначити користувача',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Не призначено'),
                      ),
                      ...availableUsers.map((user) {
                        return DropdownMenuItem<int?>(
                          value: user.id,
                          child: Text(user.username),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Дедлайн',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDeadline != null
                        ? DateFormat('dd.MM.yyyy').format(_selectedDeadline!)
                        : 'Виберіть дату',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: Text('Створити'),
        ),
      ],
    );
  }

  void _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDeadline = date;
      });
    }
  }

  void _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await boardProvider.createTask(
      title: _titleController.text,
      description: _descriptionController.text,
      deadline: _selectedDeadline,
      status: _selectedStatus,
      boardId: boardProvider.currentBoard!.id!,
      assignedUserId: _selectedUserId,
      createdBy: userProvider.currentUser!.id!, // Передаємо хто створив
    );

    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Завдання створено!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка створення завдання'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}