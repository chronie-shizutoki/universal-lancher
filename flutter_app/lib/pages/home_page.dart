import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import './webview_page.dart';
import '../providers/theme_provider.dart';

// 网络常量
const List<String> _allowedNetworks = [
  'Tenda_794FC0_5G',
  'Tenda_794FC0',
];
const String _networkWarningMessage = '您当前环境可能无法访问服务，请检查您的地理位置或尝试连接指定网络并关闭移动数据';

// 颜色常量
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
  bool _showNetworkWarning = false;
  String? _currentWifiName;
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    // 检查是否为web平台，如果是则跳过网络检查
    if (kIsWeb) {
      setState(() {
        _showNetworkWarning = false;
      });
      return;
    }
    
    try {
      // 先请求位置权限
      final locationPermission = await Permission.location.status;
      if (locationPermission != PermissionStatus.granted) {
        // 如果没有权限，请求权限
        final result = await Permission.location.request();
        if (result != PermissionStatus.granted) {
          // 如果用户拒绝了权限，尝试检查IP地址
          await _checkIpAddress();
          return;
        }
      }
      
      // 权限已授予，获取WiFi名称
      final wifiName = await _networkInfo.getWifiName();
      // 清理WiFi名称，移除可能的引号和空格
      final cleanedWifiName = wifiName?.trim().replaceAll('"', '');
      
      setState(() {
        _currentWifiName = cleanedWifiName;
        // 只有当WiFi名称为空或不在允许列表中时才显示警告
        _showNetworkWarning = cleanedWifiName == null || !_allowedNetworks.contains(cleanedWifiName);
      });
    } catch (e) {
      // 如果获取WiFi名称失败，尝试检查IP地址作为备选方案
      await _checkIpAddress();
    }
  }
  
  Future<void> _checkIpAddress() async {
    // 检查是否为web平台，如果是则跳过网络检查
    if (kIsWeb) {
      setState(() {
        _showNetworkWarning = false;
      });
      return;
    }
    
    try {
      final ip = await _networkInfo.getWifiIP();
      setState(() {
        // 如果IP地址是内部网络地址(192.168.x.x)，则不显示警告
        _showNetworkWarning = ip == null || !ip.startsWith('192.168.');
      });
    } catch (ipError) {
      // 如果都失败，默认显示警告
      setState(() {
        _showNetworkWarning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取主题Provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // 根据主题Provider确定是否是深色模式
    final bool isDarkMode = themeProvider.isDarkMode;
    
    // 根据主题模式选择颜色
    final Color buttonGradientStart = isDarkMode ? _darkButtonGradientStart : _lightButtonGradientStart;
    final Color buttonGradientEnd = isDarkMode ? _darkButtonGradientEnd : _lightButtonGradientEnd;
    final Color textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final Color textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    
    return SafeArea(
      child: Stack(
        children: [
          // 主要内容
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 普通容器
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 32.0,
                          spreadRadius: 8.0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 网络警告信息
                        if (_showNetworkWarning)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.orange.withValues(alpha: 0.5)
                                    : Colors.orange.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: isDarkMode
                                      ? Colors.orangeAccent
                                      : Colors.orange,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    _networkWarningMessage,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.orangeAccent
                                          : Colors.orange,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // 按钮组
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16.0,
                          runSpacing: 16.0,
                          children: [
                            _buildButton(
                              text: '家庭记账本',
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
                                  _navigateToUrl('http://192.168.0.197:3100');
                                });
                              },
                              buttonGradientStart: buttonGradientStart,
                              buttonGradientEnd: buttonGradientEnd,
                              textPrimary: textPrimary,
                              isDarkMode: isDarkMode,
                            ),
                            _buildButton(
                              text: '智能家居库存管理系统',
                              isPrimary: true,
                              onPressed: () {
                                _navigateToUrl('http://192.168.0.197:5000');
                              },
                              buttonGradientStart: buttonGradientStart,
                              buttonGradientEnd: buttonGradientEnd,
                              textPrimary: textPrimary,
                              isDarkMode: isDarkMode,
                            ),
                            _buildButton(
                              text: '限时福利活动',
                              isPrimary: true,
                              onPressed: () {
                                _navigateToUrl('http://192.168.0.197:3001');
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
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
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
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.3),
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(
          color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
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
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
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
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.15),
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