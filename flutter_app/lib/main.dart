import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'providers/theme_provider.dart';
import 'providers/food_provider.dart';
import 'pages/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FoodProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // 设置系统UI覆盖样式，确保状态栏颜色与主题匹配
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarBrightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
          );
          
          return MaterialApp(
            title: '统一启动器',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.materialThemeMode,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            home: const MainPage(),
          );
        },
      ),
    );
  }
}