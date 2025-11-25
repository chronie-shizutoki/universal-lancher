import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

void main() async {
  // 获取当前目录的pubspec.yaml文件路径
  final String scriptDir = p.dirname(Platform.script.toFilePath());
  final String pubspecPath = p.join(scriptDir, 'pubspec.yaml');
  
  debugPrint('正在读取pubspec.yaml文件...');
  
  // 读取pubspec.yaml文件内容
  final File pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    debugPrint('错误: 找不到pubspec.yaml文件!');
    exit(1);
  }
  
  List<String> lines = pubspecFile.readAsLinesSync();
  
  // 生成当前时间的版本号
  DateTime now = DateTime.now();
  String datePart = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  String timePart = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  int timestampSeconds = now.millisecondsSinceEpoch ~/ 1000;
  
  String newVersion = '1.$datePart.$timePart+$timestampSeconds';
  debugPrint('生成的新版本号: $newVersion');
  
  // 更新版本号行
  bool versionUpdated = false;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('version:')) {
      debugPrint('将版本号从: ${lines[i].substring(8).trim()} 更新为: $newVersion');
      lines[i] = 'version: $newVersion';
      versionUpdated = true;
      break;
    }
  }
  
  if (!versionUpdated) {
    debugPrint('错误: 在pubspec.yaml中找不到version字段!');
    exit(1);
  }
  
  // 写回pubspec.yaml文件
  try {
    pubspecFile.writeAsStringSync(lines.join('\n'));
    debugPrint('pubspec.yaml文件已成功更新!');
  } catch (e) {
    debugPrint('错误: 无法写入pubspec.yaml文件: $e');
    exit(1);
  }
}