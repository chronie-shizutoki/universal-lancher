import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 更新管理Provider
class UpdateProvider extends ChangeNotifier {
  static const String _updateUrl = 'https://universal-launcher.netlify.app/update.json';
  static const String _apkUrl = 'https://universal-launcher.netlify.app/com.chronie.universal_lancher.apk';
  
  bool _isCheckingUpdate = false;
  bool _isUpdateAvailable = false;
  bool _isDownloading = false;
  String _remoteVersion = '';
  String _localVersion = '';
  String? _errorMessage;
  // 移除未使用的_downloadPath字段
  // String? _downloadPath;
  
  bool get isCheckingUpdate => _isCheckingUpdate;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isDownloading => _isDownloading;
  String get remoteVersion => _remoteVersion;
  String get localVersion => _localVersion;
  String? get errorMessage => _errorMessage;

  /// 初始化
  Future<void> initialize() async {
    try {
      // 获取本地版本信息
      final packageInfo = await PackageInfo.fromPlatform();
      _localVersion = packageInfo.version;
      
      if (kDebugMode) {
        debugPrint('初始化完成，本地版本: $_localVersion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('初始化失败: $e');
      }
    }
  }
  
  /// 打开系统下载管理器下载APK
  Future<void> _openSystemDownloadManager() async {
    try {
      // 直接使用安卓系统下载器下载APK
      // 通过设置适当的headers和参数，让系统下载器处理下载过程
      final uri = Uri.parse(_apkUrl);
      
      if (kDebugMode) {
        debugPrint('准备打开系统下载器: $_apkUrl');
      }
      
      // 启动系统下载管理器
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: false),
      );
      
      _isDownloading = false;
      _errorMessage = '更新已开始下载，请在通知栏查看下载进度';
      
      if (kDebugMode) {
        debugPrint('系统下载器已启动');
      }
    } catch (e) {
      _isDownloading = false;
      _errorMessage = '无法启动系统下载器: $e';
      
      if (kDebugMode) {
        debugPrint('启动系统下载器失败: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// 检查更新
  Future<void> checkUpdate() async {
    _isCheckingUpdate = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_updateUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _remoteVersion = data['version'] as String;
        
        // 比较版本号
        _isUpdateAvailable = _compareVersions(_localVersion, _remoteVersion);
      } else {
        _errorMessage = '获取远程版本信息失败: ${response.statusCode}';
        if (kDebugMode) {
          debugPrint(_errorMessage);
        }
      }
    } catch (e) {
      _errorMessage = '检查更新时出错: $e';
      if (kDebugMode) {
        debugPrint(_errorMessage);
      }
    } finally {
      _isCheckingUpdate = false;
      notifyListeners();
    }
  }

  /// 比较版本号
  bool _compareVersions(String localVersion, String remoteVersion) {
    try {
      // 移除版本号前缀的v字符（如果存在）
      final local = localVersion.replaceFirst(RegExp(r'^v'), '');
      final remote = remoteVersion.replaceFirst(RegExp(r'^v'), '');
      
      // 分割版本号组件
      final localParts = local.split('.');
      final remoteParts = remote.split('.');
      
      // 比较版本号
      final maxLength = max(localParts.length, remoteParts.length);
      for (int i = 0; i < maxLength; i++) {
        final localPart = i < localParts.length ? int.tryParse(localParts[i]) ?? 0 : 0;
        final remotePart = i < remoteParts.length ? int.tryParse(remoteParts[i]) ?? 0 : 0;
        
        if (remotePart > localPart) {
          return true;
        } else if (remotePart < localPart) {
          return false;
        }
        // 如果相等，继续比较下一个组件
      }
      
      // 版本号完全相同
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('比较版本号时出错: $e');
      }
      return false;
    }
  }

  /// 下载APK文件 - 使用安卓系统下载管理器
  Future<void> downloadApk() async {
    _isDownloading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 直接调用系统下载管理器下载APK
      await _openSystemDownloadManager();
      
    } catch (e) {
      _isDownloading = false;
      _errorMessage = '下载时出错: $e';
      if (kDebugMode) {
        debugPrint(_errorMessage);
      }
      notifyListeners();
    }
  }
  
  /// 取消下载 - 由于使用系统下载管理器，此处仅更新状态
  Future<void> cancelDownload() async {
    _isDownloading = false;
    notifyListeners();
    
    // 提示用户在系统通知栏手动取消下载
    _errorMessage = '请在系统通知栏手动取消下载';
    
    if (kDebugMode) {
      debugPrint('下载已取消（状态更新）');
    }
  }
  
  /// 清理资源
  @override
  void dispose() {
    // 由于不再使用FlutterDownloader，不需要移除回调
    super.dispose();
  }

  /// 打开系统文件管理器，引导用户找到并安装已下载的APK
  Future<void> openFileManagerToInstall() async {
    try {
      if (Platform.isAndroid) {
        // 尝试打开下载文件夹
        final downloadsDirUri = Uri.parse('content://com.android.externalstorage.documents/document/primary:Download');
        
        if (kDebugMode) {
          debugPrint('准备打开下载文件夹');
        }
        
        try {
          await launchUrl(
            downloadsDirUri,
            mode: LaunchMode.externalApplication,
          );
          
          if (kDebugMode) {
            debugPrint('下载文件夹已打开');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('打开下载文件夹失败: $e');
          }
          
          // 尝试替代方法
          final downloadsPath = '/storage/emulated/0/Download';
          await launchUrl(
            Uri.parse(downloadsPath),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      _errorMessage = '无法打开文件管理器: $e';
      if (kDebugMode) {
        debugPrint(_errorMessage);
      }
      notifyListeners();
    }
  }

  /// 开始更新流程
  Future<void> startUpdateProcess() async {
    await checkUpdate();
    if (_isUpdateAvailable) {
      await downloadApk();
    }
  }


}
