import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

/// 更新管理Provider
class UpdateProvider extends ChangeNotifier {
  static const String _updateUrl = 'https://universal-launcher.netlify.app/update.json';
  static const String _apkUrl = 'https://universal-launcher.netlify.app/com.chronie.universal_lancher.apk';
  
  bool _isCheckingUpdate = false;
  bool _isUpdateAvailable = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _remoteVersion = '';
  String _localVersion = '';
  String? _errorMessage;
  String? _downloadTaskId;
  String? _downloadPath;
  
  // 用于接收下载进度回调的端口
  final ReceivePort _port = ReceivePort();
  
  bool get isCheckingUpdate => _isCheckingUpdate;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get remoteVersion => _remoteVersion;
  String get localVersion => _localVersion;
  String? get errorMessage => _errorMessage;

  /// 初始化
  Future<void> initialize() async {
    try {
      // 初始化FlutterDownloader
      await FlutterDownloader.initialize(
        debug: kDebugMode, // 开发模式下启用调试
        ignoreSsl: true,   // 允许自签名SSL证书
      );
      
      // 注册下载进度回调
      _registerCallback();
      
      // 获取本地版本信息
      final packageInfo = await PackageInfo.fromPlatform();
      _localVersion = packageInfo.version;
      
      // 获取下载路径
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        _downloadPath = directory.path;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('初始化失败: $e');
      }
    }
  }
  
  /// 注册下载进度回调
  void _registerCallback() {
    // 创建唯一的端口名称
    const String downloaderPortName = 'downloader_send_port';
    
    // 确保回调正确注册
    IsolateNameServer.removePortNameMapping(downloaderPortName);
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      downloaderPortName,
    );
    
    // 监听下载进度
    _port.listen((dynamic data) {
      if (data is Map<String, dynamic>) {
        final String taskId = data['task_id'] as String;
        final int status = data['status'] as int;
        final int progress = data['progress'] as int;
        
        // 只处理我们的下载任务
        if (taskId == _downloadTaskId) {
          _downloadProgress = progress / 100.0;
          
          if (status == DownloadTaskStatus.complete) {
    _isDownloading = false;
    if (kDebugMode) {
      debugPrint('下载完成');
    }
    // 下载完成后安装
    _installApk('$_downloadPath/com.chronie.universal_lancher.apk');
  } else if (status == DownloadTaskStatus.failed) {
    _isDownloading = false;
    _errorMessage = '下载失败';
    if (kDebugMode) {
      debugPrint('下载失败: ${data['error']}');
    }
  }
          
          notifyListeners();
        }
      }
    });
    
    // 设置下载回调
    FlutterDownloader.registerCallback(_downloadCallback);
  }
  
  /// 下载回调函数（必须是顶级函数或静态方法）
  static void _downloadCallback(String id, int status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send({'task_id': id, 'status': status, 'progress': progress});
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

  /// 下载APK文件 - 使用FlutterDownloader库（原生下载管理器）
  Future<void> downloadApk() async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // 检查并请求存储权限
      final status = await Permission.storage.request();
      if (status.isDenied) {
        _isDownloading = false;
        _errorMessage = '需要存储权限才能下载更新';
        if (kDebugMode) {
          debugPrint(_errorMessage);
        }
        notifyListeners();
        return;
      }
      
      // 确保下载路径存在
      if (_downloadPath == null) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('无法访问存储目录');
        }
        _downloadPath = directory.path;
      }
      
      final downloadDir = Directory(_downloadPath!);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      // 删除之前的下载文件
      final previousFile = File('$_downloadPath/com.chronie.universal_lancher.apk');
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
      
      // 取消之前的下载任务
      if (_downloadTaskId != null) {
        await FlutterDownloader.cancel(taskId: _downloadTaskId!);
      }
      
      // 开始新的下载任务
      _downloadTaskId = await FlutterDownloader.enqueue(
        url: _apkUrl,
        savedDir: _downloadPath!,
        fileName: 'com.chronie.universal_lancher.apk',
        showNotification: true, // 显示系统下载通知
        openFileFromNotification: false, // 不自动打开
        saveInPublicStorage: true, // 保存到公共存储
      );
      
      if (_downloadTaskId == null) {
        throw Exception('创建下载任务失败');
      }
      
      if (kDebugMode) {
        debugPrint('开始下载: $_downloadTaskId');
      }
      
    } catch (e) {
      _isDownloading = false;
      _errorMessage = '下载时出错: $e';
      if (kDebugMode) {
        debugPrint(_errorMessage);
      }
      notifyListeners();
    }
  }
  
  /// 取消下载
  Future<void> cancelDownload() async {
    if (_downloadTaskId != null) {
      await FlutterDownloader.cancel(taskId: _downloadTaskId!);
      _downloadTaskId = null;
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }
  
  /// 清理资源
  @override
  void dispose() {
    // 移除回调
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  /// 安装APK - 使用原生安装器
  Future<void> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final file = File(filePath);
        if (!await file.exists()) {
          _errorMessage = 'APK文件不存在: $filePath';
          if (kDebugMode) {
            debugPrint(_errorMessage);
          }
          notifyListeners();
          return;
        }
        
        bool installed = false;
        
        // 直接使用文件路径安装APK
        try {
          final fileUri = Uri.file(filePath);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(
              fileUri,
              mode: LaunchMode.externalApplication,
              webViewConfiguration: const WebViewConfiguration(enableJavaScript: false),
            );
            installed = true;
            if (kDebugMode) {
              debugPrint('使用文件URI安装成功');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('使用文件URI安装失败: $e');
          }
        }
        
        // 如果安装失败
        if (!installed) {
          _errorMessage = '无法安装更新，请手动安装';
          if (kDebugMode) {
            debugPrint(_errorMessage);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = '安装APK失败: $e';
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
