import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';
import '../models/task.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;

  const EditTaskDialog({Key? key, required this.task}) : super(key: key);

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDeadline;
  String _selectedStatus = 'Заплановано';
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _selectedDeadline = widget.task.deadline;
    _selectedStatus = widget.task.status;
    _selectedUserId = widget.task.assignedUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, BoardProvider>(
      builder: (context, userProvider, boardProvider, child) {
        final currentUserId = userProvider.currentUser!.id!;
        final canEditDetails = boardProvider.canEditTaskDetails(widget.task, currentUserId);
        final canEditStatus = boardProvider.canEditTask(widget.task, currentUserId);

        return AlertDialog(
          title: Text(canEditDetails ? 'Редагувати завдання' : 'Переглянути завдання'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: canEditDetails,
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
                    enabled: canEditDetails,
                    decoration: InputDecoration(
                      labelText: 'Опис',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
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
                    onChanged: canEditStatus ? (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    } : null,
                  ),
                  if (canEditDetails) ...[
                    SizedBox(height: 16),
                    _buildUserDropdown(userProvider, boardProvider),
                    SizedBox(height: 16),
                    _buildDeadlinePicker(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Скасувати'),
            ),
            if (canEditDetails || canEditStatus)
              ElevatedButton(
                onPressed: _updateTask,
                child: Text('Зберегти'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserDropdown(UserProvider userProvider, BoardProvider boardProvider) {
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
        // Перевіряємо чи може користувач зняти призначення
        if (value == null && !widget.task.originallyUnassigned) {
          // Не дозволяємо зняти призначення якщо завдання не було спочатку непризначеним
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не можна зняти призначення з цього завдання'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        setState(() {
          _selectedUserId = value;
        });
      },
    );
  }

  Widget _buildDeadlinePicker() {
    return InkWell(
      onTap: _selectDeadline,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Дедлайн',
          border: OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today),
              if (_selectedDeadline != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedDeadline = null;
                    });
                  },
                ),
            ],
          ),
        ),
        child: Text(
          _selectedDeadline != null
              ? DateFormat('dd.MM.yyyy').format(_selectedDeadline!)
              : 'Виберіть дату',
        ),
      ),
    );
  }

  void _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDeadline = date;
      });
    }
  }

  void _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final canEditDetails = boardProvider.canEditTaskDetails(widget.task, userProvider.currentUser!.id!);

    final updatedTask = widget.task.copyWith(
      title: canEditDetails ? _titleController.text : widget.task.title,
      description: canEditDetails ? _descriptionController.text : widget.task.description,
      deadline: canEditDetails ? _selectedDeadline : widget.task.deadline,
      status: _selectedStatus,
      assignedUserId: canEditDetails ? _selectedUserId : widget.task.assignedUserId,
    );

    final success = await boardProvider.updateTask(updatedTask);

    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Завдання оновлено!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка оновлення завдання'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}