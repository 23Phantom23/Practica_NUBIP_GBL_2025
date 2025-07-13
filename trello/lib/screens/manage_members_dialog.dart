import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_role.dart';
import '../models/user.dart';

class ManageMembersDialog extends StatefulWidget {
  @override
  _ManageMembersDialogState createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BoardProvider, UserProvider>(
      builder: (context, boardProvider, userProvider, child) {
        final allUsers = userProvider.allUsers;
        final boardMembersWithRoles = boardProvider.boardMembersWithRoles;
        final owner = userProvider.getUserById(boardProvider.currentBoard!.ownerId);
        final currentUserRole = boardProvider.currentUserRole;
        final isOwner = boardProvider.isOwner(userProvider.currentUser!.id!);
        
        // Отримуємо всіх користувачів які є учасниками
        final memberUserIds = boardMembersWithRoles.map((m) => m.userId).toSet();
        
        // Користувачі, які не є учасниками дошки
        final availableUsers = allUsers.where((user) => 
          user.id != boardProvider.currentBoard!.ownerId && 
          !memberUserIds.contains(user.id)
        ).toList();

        return AlertDialog(
          title: Text('Управління учасниками'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Власник дошки
                  _buildMemberTile(
                    user: owner!,
                    role: UserRole.owner,
                    isOwner: true,
                    canEdit: false,
                    onRoleChanged: null,
                    onRemove: null,
                  ),
                  
                  if (boardMembersWithRoles.isNotEmpty) Divider(),
                  
                  // Учасники дошки з ролями
                  ...boardMembersWithRoles.map((memberWithRole) {
                    final user = userProvider.getUserById(memberWithRole.userId)!;
                    final canEdit = isOwner || (currentUserRole == UserRole.manager && memberWithRole.role == UserRole.member);
                    final canRemove = isOwner || (currentUserRole == UserRole.manager && memberWithRole.role == UserRole.member);
                    
                    return _buildMemberTile(
                      user: user,
                      role: memberWithRole.role,
                      isOwner: false,
                      canEdit: canEdit,
                      onRoleChanged: canEdit ? (newRole) => _updateMemberRole(memberWithRole.userId, newRole) : null,
                      onRemove: canRemove ? () => _removeMember(memberWithRole.userId) : null,
                    );
                  }),
                  
                  if (availableUsers.isNotEmpty) ...[
                    Divider(),
                    Text('Додати учасників:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    
                    // Доступні користувачі для додавання
                    ...availableUsers.map((user) => ListTile(
                      leading: CircleAvatar(
                        child: Text(user.username.substring(0, 1).toUpperCase()),
                        backgroundColor: Colors.grey,
                      ),
                      title: Text(user.username),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOwner)
                            IconButton(
                              icon: Icon(Icons.admin_panel_settings, color: Colors.purple),
                              onPressed: () => _addMember(user.id!, UserRole.manager),
                              tooltip: 'Додати як менеджера',
                            ),
                          IconButton(
                            icon: Icon(Icons.person_add, color: Colors.green),
                            onPressed: () => _addMember(user.id!, UserRole.member),
                            tooltip: 'Додати як учасника',
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Закрити'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberTile({
    required User user,
    required UserRole role,
    required bool isOwner,
    required bool canEdit,
    Function(UserRole)? onRoleChanged,
    VoidCallback? onRemove,
  }) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.username.substring(0, 1).toUpperCase()),
        backgroundColor: _getRoleColor(role),
      ),
      title: Text(user.username),
      subtitle: Row(
        children: [
          Text(role.displayName),
          if (isOwner) ...[
            SizedBox(width: 8),
            Icon(Icons.star, size: 16, color: Colors.orange),
          ],
        ],
      ),
      trailing: canEdit ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRoleChanged != null && !isOwner)
            PopupMenuButton<UserRole>(
              icon: Icon(Icons.edit),
              onSelected: onRoleChanged,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: UserRole.manager,
                  child: Text('Менеджер'),
                ),
                PopupMenuItem(
                  value: UserRole.member,
                  child: Text('Учасник'),
                ),
              ],
            ),
          if (onRemove != null)
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: onRemove,
            ),
        ],
      ) : null,
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.orange;
      case UserRole.manager:
        return Colors.purple;
      case UserRole.member:
        return Colors.blue;
    }
  }

  void _addMember(int userId, UserRole role) async {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    final success = await boardProvider.addBoardMember(userId, role);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Учасника додано як ${role.displayName}!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка додавання учасника'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateMemberRole(int userId, UserRole newRole) async {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    await boardProvider.updateMemberRole(userId, newRole);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Роль змінено на ${newRole.displayName}!')),
    );
  }

  void _removeMember(int userId) async {
    final boardProvider = Provider.of<BoardProvider>(context, listen: false);
    await boardProvider.removeBoardMember(userId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Учасника видалено!')),
    );
  }
}