import 'package:flutter/material.dart';
import 'home_page.dart';
import 'calculator_selection_page.dart';
import 'food_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  Widget? _calculatorPage;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      CalculatorSelectionPage(onCalculatorSelected: _setCalculatorPage),
      const FoodPage(),
      const SettingsPage(),
    ];
  }

  // 设置当前显示的计算器页面
  void _setCalculatorPage(Widget? page) {
    setState(() {
      _calculatorPage = page;
    });
  }

  // 获取当前要显示的页面
  Widget _getCurrentPage() {
    if (_currentIndex == 1) {
      return _calculatorPage ?? _pages[1];
    }
    return _pages[_currentIndex];
  }

  final List<String> _titles = [
    '首页',
    '计算器',
    '今天吃什么',
    '设置',
  ];
  
  // 导航项图标
  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.calculate_outlined,
    Icons.restaurant_outlined,
    Icons.settings_outlined,
  ];
  
  final List<IconData> _activeIcons = [
    Icons.home,
    Icons.calculate,
    Icons.restaurant,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768; // 定义大屏幕阈值

    return Scaffold(
      body: isLargeScreen
          ? Column(
              children: [
                // 顶部导航栏
                _buildTopNavBar(),
                // 主内容区域
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _getCurrentPage(),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                // 使用SafeArea确保内容在状态栏下方显示
                SafeArea(
                  child: _getCurrentPage(),
                ),
                // 底部悬浮导航栏
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomNavBar(),
                ),
              ],
            ),
    );
  }
  
  // 构建顶部导航栏（大屏幕）
  Widget _buildTopNavBar() {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: _getGlassmorphismDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_pages.length, (index) {
            bool isSelected = _currentIndex == index;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: isDarkMode 
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: Text(
                    _titles[index],
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isDarkMode
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  
  // 构建底部悬浮导航栏（小屏幕）
  Widget _buildBottomNavBar() {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1, // 水平边距自适应
        vertical: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _getGlassmorphismDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_pages.length, (index) {
          bool isSelected = _currentIndex == index;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: isDarkMode 
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: Icon(
                    isSelected ? _activeIcons[index] : _icons[index],
                    size: 24,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isDarkMode
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
  
  // 液态玻璃效果装饰
  BoxDecoration _getGlassmorphismDecoration() {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return BoxDecoration(
      color: isDarkMode 
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: isDarkMode 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode 
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.5),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }
}