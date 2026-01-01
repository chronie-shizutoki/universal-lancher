import 'package:flutter/material.dart';
import 'home_page.dart';
import 'check_service_page.dart';
import 'rate_calculator_page.dart';
import 'food_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _pages = [
    const HomePage(),
    const CheckServicePage(),
    const RateCalculatorPage(),
    const FoodPage(),
    const SettingsPage(),
  ];

  final List<String> _titles = [
    '首页',
    '服务状态监控',
    '货币兑换计算器',
    '今天吃什么',
    '设置',
  ];
  
  // 导航项图标
  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.health_and_safety_outlined,
    Icons.calculate_outlined,
    Icons.restaurant_outlined,
    Icons.settings_outlined,
  ];
  
  // 选中状态图标
  final List<IconData> _activeIcons = [
    Icons.home,
    Icons.health_and_safety,
    Icons.calculate,
    Icons.restaurant,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768; // 定义大屏幕阈值
    final isExtraLargeScreen = screenWidth > 1024; // 定义超大屏幕阈值

    return Scaffold(
      body: isLargeScreen
          ? Row(
              children: [
                // 左侧导航栏
                _buildLeftSideNavBar(isExtraLargeScreen, screenWidth),
                // 主内容区域
                Expanded(
                  child: SafeArea(
                    child: _pages[_currentIndex],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                // 使用SafeArea确保内容在状态栏下方显示
                SafeArea(
                  child: _pages[_currentIndex],
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
  
  // 构建左侧导航栏（大屏幕）
  Widget _buildLeftSideNavBar(bool isExtraLargeScreen, double screenWidth) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    // 计算导航栏宽度，至少占用屏幕15%的宽度
    final minNavBarWidth = screenWidth * 0.15;
    final navBarWidth = isExtraLargeScreen 
        ? (200 > minNavBarWidth ? 200 : minNavBarWidth) 
        : (80 > minNavBarWidth ? 80 : minNavBarWidth);
    
    return Container(
      width: navBarWidth.toDouble(),
      margin: const EdgeInsets.all(16),
      decoration: _getGlassmorphismDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 按钮组不再居中显示
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 32), // 顶部留白
          ...List.generate(_pages.length, (index) {
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
                  padding: isExtraLargeScreen 
                      ? const EdgeInsets.symmetric(vertical: 20, horizontal: 24)
                      : const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                  child: isExtraLargeScreen
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? _activeIcons[index] : _icons[index],
                              size: 32,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : isDarkMode
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.black.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _titles[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : isDarkMode
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : Colors.black.withValues(alpha: 0.7),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? _activeIcons[index] : _icons[index],
                              size: 32,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : isDarkMode
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.black.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }),
        ],
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