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
  // 常量定义，避免硬编码
  static const String _loadingText = '加载中...';
  static const String _fetchFailedText = '获取失败';
  static const String _appStoreUrl = 'https://chronie-app-store.netlify.app/';
  static const String _errorMessageCannotOpen = '无法打开应用商店';
  static const String _errorMessageGeneric = '打开应用商店时出错';
  static const String _formatYear = '年';
  static const String _formatMonth = '月';
  static const String _formatDay = '日';
  
  String _version = _loadingText;
  String _buildTime = _loadingText;
  
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
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildGlassCard(
          context,
          '外观设置',
          [
            _buildThemeModeTile(themeProvider),
          ],
        ),
        
        const SizedBox(height: 16),
        
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
          ],
        ),
        
        const SizedBox(height: 60),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: InkWell(
        onTap: () {
          _showThemeBottomSheet(context, themeProvider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
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
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '选择主题模式',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildThemeOption(
                      context,
                      AppThemeModeType.light,
                      '浅色模式',
                      Icons.light_mode,
                      themeProvider,
                    ),
                    const SizedBox(height: 8),
                    _buildThemeOption(
                      context,
                      AppThemeModeType.dark,
                      '深色模式',
                      Icons.dark_mode,
                      themeProvider,
                    ),
                    const SizedBox(height: 8),
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
        );
      },
    );
  }

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
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
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
}