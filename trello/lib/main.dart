import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/user_provider.dart';
import 'providers/board_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'utils/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
      ],
      child: MaterialApp(
        title: 'Trello Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            // Перевіряємо чи є збережений логін при запуску
            if (userProvider.currentUser == null) {
              userProvider.checkSavedLogin();
              return AuthScreen();
            }
            return userProvider.currentUser == null 
                ? AuthScreen() 
                : HomeScreen();
          },
        ),
      ),
    );
  }
}