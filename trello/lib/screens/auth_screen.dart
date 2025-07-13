import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/app_state_provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    // Перевіряємо чи є збережений логін при завантаженні
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).checkSavedLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Colors.blue[700],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isLoginMode ? 'Вхід' : 'Реєстрація',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 24),
                    if (!_isLoginMode)
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Ім\'я користувача',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (!_isLoginMode && (value == null || value.isEmpty)) {
                            return 'Введіть ім\'я користувача';
                          }
                          return null;
                        },
                      ),
                    if (!_isLoginMode) SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введіть email';
                        }
                        if (!value.contains('@')) {
                          return 'Введіть коректний email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введіть пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль повинен містити мінімум 6 символів';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return CheckboxListTile(
                          title: Text('Запам\'ятати мене'),
                          value: userProvider.rememberMe,
                          onChanged: (value) {
                            userProvider.setRememberMe(value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Consumer<AppStateProvider>(
                      builder: (context, appState, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: appState.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: appState.isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isLoginMode ? 'Увійти' : 'Зареєструватися',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode
                            ? 'Немає акаунту? Зареєструйтеся'
                            : 'Вже є акаунт? Увійдіть',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    appState.setLoading(true);

    bool success;
    if (_isLoginMode) {
      success = await userProvider.login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await userProvider.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );
    }

    appState.setLoading(false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLoginMode 
              ? 'Неправильний email або пароль' 
              : 'Помилка реєстрації'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}