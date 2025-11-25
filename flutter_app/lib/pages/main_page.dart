import 'package:flutter/material.dart';
import 'home_page.dart';
import 'check_service_page.dart';
import 'rate_calculator_page.dart';
import 'settings_page.dart';
import 'food_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CheckServicePage(),
    const RateCalculatorPage(),
    const FoodPage(),
    const SettingsPage(),
  ];

  final List<String> _titles = [
    '统一启动器',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 使用Stack确保内容不会被悬浮导航栏遮挡
      body: Stack(
        children: [
          _pages[_currentIndex],
          // 悬浮导航栏放在内容上方
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }
  
  // 构建悬浮胶囊样式的导航栏
  Widget _buildFloatingNavBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度调整图标大小
        double getIconSize() {
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth < 360) return 20; // 小屏幕
          if (screenWidth < 600) return 24; // 中等屏幕
          return 28; // 大屏幕
        }
        
        double iconSize = getIconSize();
        
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05, // 水平边距自适应
            vertical: 10,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_pages.length, (index) {
              bool isSelected = _currentIndex == index;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : const BoxDecoration(),
                      transform: isSelected ? Matrix4.translationValues(0, -3, 0) : Matrix4.identity(),
                      child: AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isSelected ? _activeIcons[index] : _icons[index],
                          size: iconSize,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}