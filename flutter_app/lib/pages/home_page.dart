import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './webview_page.dart';
import '../providers/theme_provider.dart';

// 颜色常量
const Color _lightPrimaryGradientStart = Color(0xFFf5f7fa);
const Color _lightPrimaryGradientEnd = Color(0xFFc3cfe2);
const Color _darkPrimaryGradientStart = Color(0xFF1a1a2e);
const Color _darkPrimaryGradientEnd = Color(0xFF16213e);

const Color _lightButtonGradientStart = Color(0xFFb8e0ff);
const Color _lightButtonGradientEnd = Color(0xFF7f5af0);
const Color _darkButtonGradientStart = Color(0xFF4a5568);
const Color _darkButtonGradientEnd = Color(0xFF2d3748);

const Color _lightTextPrimary = Color(0xFF333333);
const Color _lightTextSecondary = Color(0xFF555555);
const Color _darkTextPrimary = Color(0xFFe2e8f0);
const Color _darkTextSecondary = Color(0xFFa0aec0);

/// 主页面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isModalVisible = false;

  @override
  Widget build(BuildContext context) {
    // 获取主题Provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // 根据主题Provider确定是否是深色模式
    final bool isDarkMode = themeProvider.isDarkMode;
    
    // 根据主题模式选择颜色
    final Color primaryGradientStart = isDarkMode ? _darkPrimaryGradientStart : _lightPrimaryGradientStart;
    final Color primaryGradientEnd = isDarkMode ? _darkPrimaryGradientEnd : _lightPrimaryGradientEnd;
    final Color buttonGradientStart = isDarkMode ? _darkButtonGradientStart : _lightButtonGradientStart;
    final Color buttonGradientEnd = isDarkMode ? _darkButtonGradientEnd : _lightButtonGradientEnd;
    final Color textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final Color textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    
    return Scaffold(
      body: Container(
        // 渐变背景
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryGradientStart,
              primaryGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 主要内容
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 玻璃态容器
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.3),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 32.0,
                              spreadRadius: 8.0,
                            ),
                          ],
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: Column(
                            children: [
                              // 按钮组
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 16.0,
                                children: [
                                  _buildButton(
                                    text: '记账',
                                    isPrimary: true,
                                    onPressed: () {
                                      _navigateToUrl('http://192.168.0.197:3010');
                                    },
                                    buttonGradientStart: buttonGradientStart,
                                    buttonGradientEnd: buttonGradientEnd,
                                    textPrimary: textPrimary,
                                    isDarkMode: isDarkMode,
                                  ),
                                  _buildButton(
                                    text: '金流',
                                    isPrimary: true,
                                    onPressed: () {
                                      setState(() {
                                        _isModalVisible = true;
                                      });
                                    },
                                    buttonGradientStart: buttonGradientStart,
                                    buttonGradientEnd: buttonGradientEnd,
                                    textPrimary: textPrimary,
                                    isDarkMode: isDarkMode,
                                  ),
                                  _buildButton(
                                    text: '库存',
                                    isPrimary: true,
                                    onPressed: () {
                                      _navigateToUrl('http://192.168.0.197:5000');
                                    },
                                    buttonGradientStart: buttonGradientStart,
                                    buttonGradientEnd: buttonGradientEnd,
                                    textPrimary: textPrimary,
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 模态框
              AnimatedOpacity(
                opacity: _isModalVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedScale(
                  scale: _isModalVisible ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !_isModalVisible,
                    child: _buildModal(
                      buttonGradientStart: buttonGradientStart,
                      buttonGradientEnd: buttonGradientEnd,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建按钮
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
    required Color buttonGradientStart,
    required Color buttonGradientEnd,
    required Color textPrimary,
    required bool isDarkMode,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              buttonGradientStart,
              buttonGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 10.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            side: BorderSide(
              color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
              width: 1.0,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: isDarkMode 
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.3),
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(
          color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
        ),
      ),
    );
  }

  // 构建模态框
  Widget _buildModal({
    required Color buttonGradientStart,
    required Color buttonGradientEnd,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isModalVisible = false;
        });
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDarkMode 
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 32.0,
                  spreadRadius: 8.0,
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: GestureDetector(
                  onTap: () {
                    // 阻止点击事件传递到父容器
                  },
                  behavior: HitTestBehavior.opaque, // 添加这个属性来确保内部点击不触发外部关闭
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '金流版本选择',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '点击空白处以关闭',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModalButton(
                          text: '标准',
                          onPressed: () {
                            _navigateToUrl('http://192.168.0.197:3100');
                            setState(() {
                              _isModalVisible = false;
                            });
                          },
                          buttonGradientStart: buttonGradientStart,
                          buttonGradientEnd: buttonGradientEnd,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 16.0),
                        _buildModalButton(
                          text: '兼容',
                          onPressed: () {
                            _navigateToUrl('http://192.168.0.197:4173');
                            setState(() {
                              _isModalVisible = false;
                            });
                          },
                          buttonGradientStart: buttonGradientStart,
                          buttonGradientEnd: buttonGradientEnd,
                          isDarkMode: isDarkMode,
                        ),
                      ],
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

  // 构建模态框按钮
  Widget _buildModalButton({
    required String text,
    required VoidCallback onPressed,
    required Color buttonGradientStart,
    required Color buttonGradientEnd,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            buttonGradientStart,
            buttonGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 导航到URL
  void _navigateToUrl(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          title: '外部链接',
          url: url,
        ),
      ),
    );
  }
}