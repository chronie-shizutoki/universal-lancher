import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/theme_provider.dart';
import '../providers/update_provider.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 常量定义，避免硬编码
  static const String _loadingText = '加载中...';
  static const String _fetchFailedText = '获取失败';
  static const String _appStoreUrl = 'https://universal-launcher.netlify.app/app-store.html';
  static const String _errorMessageCannotOpen = '无法打开应用商店';
  static const String _errorMessageGeneric = '打开应用商店时出错';
  static const String _formatYear = '年';
  static const String _formatMonth = '月';
  static const String _formatDay = '日';
  
  String _version = _loadingText;
  String _buildTime = _loadingText;
  bool _isThemeSelectorOpen = false;
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        // 从版本号中提取构建时间信息
        // 格式为：1.年月日.时分+时间戳
        if (_version.contains('.')) {
          List<String> parts = _version.split('.');
          if (parts.length >= 2) {
            String datePart = parts[1];
            String timePart = parts.length >= 3 ? parts[2].split('+')[0] : '';
            
            // 解析日期部分 (YYYYMMDD)
            if (datePart.length == 8) {
              String year = datePart.substring(0, 4);
              String month = datePart.substring(4, 6);
              String day = datePart.substring(6, 8);
              
              // 解析时间部分 (HHMM)
              String timeStr = '';
              if (timePart.length >= 4) {
                String hour = timePart.substring(0, 2);
                String minute = timePart.substring(2, 4);
                timeStr = '$hour:$minute';
              }
              
              _buildTime = '$year$_formatYear$month$_formatMonth$day$_formatDay $timeStr';
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _version = _fetchFailedText;
        _buildTime = _fetchFailedText;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<ThemeProvider>(
      builder: (context, _, __) {
        return GestureDetector(
          onTap: () {
            if (_isThemeSelectorOpen) {
              setState(() {
                _isThemeSelectorOpen = false;
              });
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 外观设置卡片
              _buildGlassCard(
                context,
                '外观设置',
                [
                  _buildThemeModeTile(themeProvider),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 应用信息卡片
              _buildGlassCard(
                context,
                '应用信息',
                [
                  _buildGlassInfoTile(
                    context,
                    '版本信息',
                    _version,
                    Icons.apps_outage,
                  ),
                  const Divider(height: 1),
                  _buildGlassInfoTile(
                    context,
                    '构建时间',
                    _buildTime,
                    Icons.access_time,
                  ),
                  const Divider(height: 1),
                  _buildGlassInfoTile(
                    context,
                    '应用商店',
                    '前往应用商店',
                    Icons.store,
                    onTap: () {
                      _launchAppStore();
                    },
                  ),
                  const Divider(height: 1),
                  _buildGlassInfoTile(
                    context,
                    '检查更新',
                    '检查新版本',
                    Icons.system_update_alt_outlined,
                    onTap: () {
                      _manualCheckUpdate();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 操作按钮
              _buildActionButtons(themeProvider),
              // 底部安全占位区域，确保内容不被底部导航栏遮挡
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  /// 构建玻璃风格卡片
  Widget _buildGlassCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// 构建主题模式选择项
  Widget _buildThemeModeTile(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isThemeSelectorOpen = !_isThemeSelectorOpen;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  themeProvider.themeModeIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主题模式',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeProvider.themeModeText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isThemeSelectorOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            
            // 自定义下拉菜单
            if (_isThemeSelectorOpen)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildThemeOption(
                      context,
                      AppThemeModeType.light,
                      '浅色模式',
                      Icons.light_mode,
                      themeProvider,
                    ),
                    _buildThemeOption(
                      context,
                      AppThemeModeType.dark,
                      '深色模式',
                      Icons.dark_mode,
                      themeProvider,
                    ),
                    _buildThemeOption(
                      context,
                      AppThemeModeType.system,
                      '跟随系统',
                      Icons.brightness_auto,
                      themeProvider,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建主题选项
  Widget _buildThemeOption(
    BuildContext context,
    AppThemeModeType mode,
    String label,
    IconData icon,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.currentThemeMode == mode;
    
    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(mode);
        setState(() {
          _isThemeSelectorOpen = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建玻璃风格信息项
  Widget _buildGlassInfoTile(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, { 
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios, 
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮区域
  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _showResetDialog();
            },
            icon: Icon(Icons.restore, color: Theme.of(context).colorScheme.onPrimary),
            label: Text('恢复默认设置', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// 打开应用商店
  Future<void> _launchAppStore() async {
    try {
      // 确保URL有协议前缀
      final url = _appStoreUrl.startsWith(RegExp(r'https?://')) 
        ? _appStoreUrl 
        : 'https://$_appStoreUrl';

      final bool launched = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication, // 使用默认浏览器打开
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessageCannotOpen)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_errorMessageGeneric: $e')),
        );
      }
    }
  }

  /// 显示重置确认对话框
  Future<void> _manualCheckUpdate() async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('检查更新'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('正在检查新版本...'),
            ],
          ),
        );
      },
    );
    
    try {
      // 确保初始化
      if (updateProvider.localVersion.isEmpty) {
        await updateProvider.initialize();
      }
      
      await updateProvider.checkUpdate();
      
      // 检查widget是否仍然挂载
      if (!mounted) return;
      
      // 关闭加载对话框
      Navigator.pop(context);
      
      if (updateProvider.isUpdateAvailable) {
        _showUpdateDialog(context, updateProvider);
      } else {
        // 显示已是最新版本的提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前已是最新版本')),
        );
      }
    } catch (e) {
      // 检查widget是否仍然挂载
      if (!mounted) return;
      
      // 关闭加载对话框
      Navigator.pop(context);
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败: $e')),
      );
    }
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
              onPressed: () async {
                Navigator.pop(context);
                
                // 显示下载进度对话框
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return Consumer<UpdateProvider>(
                      builder: (context, provider, child) {
                        return AlertDialog(
                          title: const Text('下载更新'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              provider.isDownloading
                                  ? const Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text('正在启动系统下载器...'),
                                      ],
                                    )
                                  : const SizedBox(),
                              const SizedBox(height: 8),
                              Text(
                                '系统下载管理器提供更稳定的下载体验',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '请在系统通知栏查看下载进度',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (provider.errorMessage != null) const SizedBox(height: 16),
                              if (provider.errorMessage != null)
                                Text(
                                  provider.errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                ),
                              if (!provider.isDownloading && !provider.isCheckingUpdate) ...[
                                const SizedBox(height: 16),
                                Text('下载已开始，点击下方按钮打开下载文件夹安装'),
                              ],
                            ],
                          ),
                          actions: [
                            if (provider.isDownloading)
                              TextButton(
                                onPressed: () async {
                                  await provider.cancelDownload();
                                  // 不立即关闭对话框，让用户看到取消提示
                                },
                                child: const Text('取消下载'),
                              ),
                            if (!provider.isDownloading && !provider.isCheckingUpdate)
                              ElevatedButton(
                                onPressed: () async {
                                  await provider.openFileManagerToInstall();
                                  // 检查widget是否仍然挂载
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('打开下载文件夹'),
                              ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('关闭'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                
                // 开始下载
                await updateProvider.downloadApk();
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('恢复默认设置'),
          content: const Text('确定要恢复默认设置吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 重置为主题模式为系统默认
                final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                themeProvider.setThemeMode(AppThemeModeType.system);
                Navigator.of(context).pop();
                
                // 检查widget是否仍然挂载
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已恢复默认设置')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}