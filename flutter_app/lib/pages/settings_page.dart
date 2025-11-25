import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/theme_provider.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '加载中...';
  String _buildTime = '加载中...';
  
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
              
              _buildTime = '$year年$month月$day日 $timeStr';
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _version = '获取失败';
        _buildTime = '获取失败';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
            children: [
              // 外观设置卡片
              _buildSectionCard(
                context,
                '外观设置',
                [
                  _buildThemeModeTile(themeProvider),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 应用信息卡片
              _buildSectionCard(
                context,
                '应用信息',
                [
                  _buildInfoTile(
                    context,
                    '应用名称',
                    '统一启动器',
                    Icons.info_outline,
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    '版本信息',
                    _version,
                    Icons.apps_outage,
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    '构建时间',
                    _buildTime,
                    Icons.access_time,
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    context,
                    '应用商店',
                    '前往应用商店',
                    Icons.store,
                    onTap: () {
                      _launchAppStore();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 操作按钮
              _buildActionButtons(themeProvider),
            ],
          );
        },
      );
  }

  /// 构建设置分区卡片
  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 构建主题模式选择项
  Widget _buildThemeModeTile(ThemeProvider themeProvider) {
    return ListTile(
      leading: Icon(
        themeProvider.themeModeIcon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('主题模式'),
      subtitle: Text(themeProvider.themeModeText),
      trailing: DropdownButton<AppThemeModeType>(
        value: themeProvider.currentThemeMode,
        onChanged: (AppThemeModeType? newMode) {
          if (newMode != null) {
            themeProvider.setThemeMode(newMode);
          }
        },
        items: const [
          DropdownMenuItem(
            value: AppThemeModeType.light,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.light_mode, size: 20),
                SizedBox(width: 8),
                Text('浅色模式'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: AppThemeModeType.dark,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dark_mode, size: 20),
                SizedBox(width: 8),
                Text('深色模式'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: AppThemeModeType.system,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.brightness_auto, size: 20),
                SizedBox(width: 8),
                Text('跟随系统'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoTile(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, { 
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {
        // 可以添加点击事件，比如显示更多详情
      },
    );
  }
  
  /// 打开应用商店
  Future<void> _launchAppStore() async {
    const appStoreUrl = 'https://universal-launcher.netlify.app/app-store.html';
    if (await canLaunchUrlString(appStoreUrl)) {
      await launchUrlString(appStoreUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开应用商店')),
      );
    }
  }

  /// 构建操作按钮区域
  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _showResetDialog();
              },
              icon: const Icon(Icons.restore),
              label: const Text('恢复默认设置'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示重置确认对话框
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已恢复默认设置')),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}