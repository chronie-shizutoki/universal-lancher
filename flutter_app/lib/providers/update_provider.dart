import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final packageInfo = await PackageInfo.fromPlatform();
      _localVersion = packageInfo.version;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('获取本地版本信息失败: $e');
      }
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

  /// 下载APK文件
  Future<void> downloadApk() async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // 获取存储目录
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('无法访问存储目录');
      }
      
      final filePath = '${directory.path}/universal_launcher.apk';
      final file = File(filePath);
      
      // 确保目录存在
      await directory.create(recursive: true);
      
      // 开始下载
      final request = http.Request('GET', Uri.parse(_apkUrl));
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int downloadedBytes = 0;
        
        final sink = file.openWrite();
        await response.stream.listen(
          (List<int> chunk) {
            downloadedBytes += chunk.length;
            _downloadProgress = totalBytes > 0 ? downloadedBytes / totalBytes : 0;
            notifyListeners();
            sink.add(chunk);
          },
          onDone: () async {
            await sink.close();
            _isDownloading = false;
            notifyListeners();
            // 下载完成后安装APK
            await _installApk(filePath);
          },
          onError: (error) async {
            await sink.close();
            _isDownloading = false;
            _errorMessage = '下载失败: $error';
            if (kDebugMode) {
              debugPrint(_errorMessage);
            }
            notifyListeners();
          },
        ).asFuture();
      } else {
        _isDownloading = false;
        _errorMessage = '下载失败: ${response.statusCode}';
        if (kDebugMode) {
          debugPrint(_errorMessage);
        }
        notifyListeners();
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

  /// 安装APK
  Future<void> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('APK文件不存在: $filePath');
        }
        
        // 尝试多种安装方式以提高兼容性
        bool installed = false;
        
        // 方法1: 直接使用文件URI启动
        try {
          final fileUri = Uri.file(filePath);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(
              fileUri,
              mode: LaunchMode.externalApplication,
              webViewConfiguration: const WebViewConfiguration(enableJavaScript: false),
            );
            installed = true;
          }
        } catch (e1) {
          if (kDebugMode) {
            debugPrint('安装方法1失败: $e1');
          }
        }
        
        // 方法2: 使用ACTION_VIEW意图
        if (!installed) {
          try {
            final intentUrl = 'intent:#Intent;action=android.intent.action.VIEW;scheme=file;path=$filePath;type=application/vnd.android.package-archive;end';
            if (await canLaunchUrl(Uri.parse(intentUrl))) {
              await launchUrl(
                Uri.parse(intentUrl),
                mode: LaunchMode.externalApplication,
              );
              installed = true;
            }
          } catch (e2) {
            if (kDebugMode) {
              debugPrint('安装方法2失败: $e2');
            }
          }
        }
        
        // 方法3: 使用content:// URI（适用于Android 7+）
        if (!installed) {
          try {
            final contentUrl = 'content://$filePath';
            if (await canLaunchUrl(Uri.parse(contentUrl))) {
              await launchUrl(
                Uri.parse(contentUrl),
                mode: LaunchMode.externalApplication,
              );
              installed = true;
            }
          } catch (e3) {
            if (kDebugMode) {
              debugPrint('安装方法3失败: $e3');
            }
          }
        }
        
        if (!installed) {
          _errorMessage = '无法启动安装程序，请手动安装APK文件';
          if (kDebugMode) {
            debugPrint(_errorMessage);
          }
          notifyListeners();
        }
      } else {
        _errorMessage = '当前平台不支持安装APK';
        if (kDebugMode) {
          debugPrint(_errorMessage);
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '安装APK时出错: $e';
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

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
