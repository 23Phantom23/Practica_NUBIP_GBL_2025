import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  List<User> _allUsers = [];
  bool _rememberMe = false;

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('user_id');
    
    if (savedUserId != null) {
      final user = await DatabaseHelper.instance.getUserById(savedUserId);
      if (user != null) {
        _currentUser = user;
        await loadAllUsers();
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await DatabaseHelper.instance.getUserByEmailAndPassword(email, password);
      if (user != null) {
        _currentUser = user;
        await loadAllUsers();
        
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', user.id!);
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      final user = User(
        username: username,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );
      
      final id = await DatabaseHelper.instance.createUser(user);
      _currentUser = user.copyWith(id: id);
      await loadAllUsers();
      
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', id);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> loadAllUsers() async {
    try {
      _allUsers = await DatabaseHelper.instance.getAllUsers();
      notifyListeners();
    } catch (e) {
      print('Load users error: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    
    _currentUser = null;
    _allUsers = [];
    _rememberMe = false;
    notifyListeners();
  }

  User? getUserById(int id) {
    try {
      return _allUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}