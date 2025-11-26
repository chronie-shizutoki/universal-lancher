import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'check_service_page.dart';
import 'rate_calculator_page.dart';
import 'settings_page.dart';
import 'food_page.dart';
import '../providers/update_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    // 初始化UpdateProvider并检查更新
    _initializeAndCheckUpdate();
  }

  Future<void> _initializeAndCheckUpdate() async {
    try {
      final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
      await updateProvider.initialize();
      
      // 延迟一下再检查更新，让应用先完全加载
      Future.delayed(const Duration(seconds: 2), () {
        _checkUpdate();
      });
    } catch (e) {
      if (kDebugMode) {
        print('初始化更新检查失败: $e');
      }
    }
  }

  void _checkUpdate() {
    if (_hasCheckedUpdate) return;
    
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    updateProvider.checkUpdate().then((_) {
      _hasCheckedUpdate = true;
      if (updateProvider.isUpdateAvailable) {
        // 在UI线程中显示更新对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(context, updateProvider);
        });
      }
    });
  }

  void _showUpdateDialog(BuildContext context, UpdateProvider updateProvider) {
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('发现新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前版本: ${updateProvider.localVersion}'),
              Text('最新版本: ${updateProvider.remoteVersion}'),
              const SizedBox(height: 8),
              const Text('使用系统下载管理器，下载更稳定'),
              const SizedBox(height: 16),
              const Text('是否立即更新应用？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDownloadProgressDialog(context);
                updateProvider.downloadApk();
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      }
    );
  }

  void _showDownloadProgressDialog(BuildContext context) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('下载更新'),
          content: Consumer<UpdateProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: provider.downloadProgress,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text('下载进度: ${(provider.downloadProgress * 100).toStringAsFixed(0)}%'),
                  SizedBox(height: 4),
                  Text(
                    '使用系统下载管理器，支持后台下载和断点续传',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (provider.errorMessage != null) ...[
                    SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                  if (!provider.isDownloading && provider.errorMessage == null) ...[
                    SizedBox(height: 8),
                    Text('下载完成，准备安装...'),
                  ],
                ],
              );
            },
          ),
          actions: [
            Consumer<UpdateProvider>(
              builder: (context, provider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (provider.isDownloading) ...[
                      TextButton(
                        onPressed: () async {
                          await provider.cancelDownload();
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: Text('取消下载'),
                      ),
                    ],
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: provider.isDownloading ? Text('后台下载') : Text('关闭'),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

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