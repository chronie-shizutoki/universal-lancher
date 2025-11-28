import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum AppThemeModeType { light, dark, system }

/// 主题管理Provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  AppThemeModeType _currentThemeMode = AppThemeModeType.system;
  
  AppThemeModeType get currentThemeMode => _currentThemeMode;

  // 当前是否处于深色模式
  bool get isDarkMode {
    switch (_currentThemeMode) {
      case AppThemeModeType.light:
        return false;
      case AppThemeModeType.dark:
        return true;
      case AppThemeModeType.system:
        // 返回系统主题检测结果
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  // 主题数据
  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        brightness: Brightness.light,
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        surface: const Color(0xFFF8F9FA),
        error: const Color(0xFFDC3545),
      ),
      useMaterial3: true,
      fontFamily: 'system-ui', // 使用系统字体
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'system-ui',
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF667eea),
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF667eea),
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E6ED),
        thickness: 1,
        space: 1,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        brightness: Brightness.dark,
        primary: const Color(0xFF8B9AFF),
        secondary: const Color(0xFFA889FF),
        surface: const Color(0xFF1E1E1E),
        error: const Color(0xFFFF5252),
        onSurface: const Color(0xFFE0E0E0),
      ),
      useMaterial3: true,
      fontFamily: 'system-ui', // 使用系统字体
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'system-ui',
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2D3748),
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B9AFF),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D3748),
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B9AFF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF8B9AFF),
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF4A5568),
        thickness: 1,
        space: 1,
      ),
    );
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedMode = prefs.getInt(_themeModeKey);
      
      if (savedMode != null && savedMode >= 0 && savedMode < AppThemeModeType.values.length) {
        _currentThemeMode = AppThemeModeType.values[savedMode];
      }
      notifyListeners();
    } catch (e) {
      // 加载失败时使用默认值
      _currentThemeMode = AppThemeModeType.system;
      notifyListeners();
    }
  }

  /// 保存主题模式
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _currentThemeMode.index);
    } catch (e) {
      // 保存失败时记录日志
      debugPrint('保存主题模式失败: $e');
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeModeType mode) async {
    _currentThemeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  /// 切换浅色/深色模式
  Future<void> toggleTheme() async {
    switch (_currentThemeMode) {
      case AppThemeModeType.light:
        _currentThemeMode = AppThemeModeType.dark;
        break;
      case AppThemeModeType.dark:
        _currentThemeMode = AppThemeModeType.light;
        break;
      case AppThemeModeType.system:
        // 如果是系统模式，则根据当前系统主题切换到相反的模式
        _currentThemeMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? AppThemeModeType.light
            : AppThemeModeType.dark;
        break;
    }
    await _saveThemeMode();
    notifyListeners();
  }

  /// 获取Material的主题模式
  ThemeMode get materialThemeMode {
    switch (_currentThemeMode) {
      case AppThemeModeType.light:
        return ThemeMode.light;
      case AppThemeModeType.dark:
        return ThemeMode.dark;
      case AppThemeModeType.system:
        return ThemeMode.system;
    }
  }

  /// 获取主题模式显示文本
  String get themeModeText {
    switch (_currentThemeMode) {
      case AppThemeModeType.light:
        return '浅色模式';
      case AppThemeModeType.dark:
        return '深色模式';
      case AppThemeModeType.system:
        return '跟随系统';
    }
  }

  /// 获取主题模式图标
  IconData get themeModeIcon {
    switch (_currentThemeMode) {
      case AppThemeModeType.light:
        return Icons.light_mode;
      case AppThemeModeType.dark:
        return Icons.dark_mode;
      case AppThemeModeType.system:
        return Icons.brightness_auto;
    }
  }
}