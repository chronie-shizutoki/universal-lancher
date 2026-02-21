import 'dart:io';
void main() {
  // 获取当前日期时间
  final now = DateTime.now();
  
  // 生成版本号部分 - 使用Dart内置方法格式化日期，避免依赖intl包
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  
  final dateStr = '$year$month$day';
  final timeStr = '$hour$minute';
  final timestamp = now.millisecondsSinceEpoch ~/ 1000; // 转换为秒级时间戳
  
  // 格式化为：1.年月日.时分+时间戳
  final version = '1.$dateStr.$timeStr+$timestamp';
  
  print('生成的版本号: $version');
  
  // 更新pubspec.yaml文件
  updatePubspecYaml(version);
}

void updatePubspecYaml(String version) {
  // 获取脚本所在目录，然后构建pubspec.yaml的路径
  final scriptDir = Directory.current.path;
  
  // 尝试不同的路径来找到pubspec.yaml
  List<String> possiblePaths = [
    '$scriptDir/pubspec.yaml',
    '$scriptDir/../pubspec.yaml',
    'd:/chronie-app/universal-lancher/flutter_app/pubspec.yaml' // 绝对路径作为后备
  ];
  
  File? file;
  for (final path in possiblePaths) {
    final testFile = File(path);
    if (testFile.existsSync()) {
      file = testFile;
      break;
    }
  }
  
  if (file == null) {
    print('错误: 无法找到pubspec.yaml文件');
    print('请确保在正确的目录下运行此脚本');
    exit(1);
  }
  
  // 输出找到的pubspec.yaml路径，便于调试
  print('找到 pubspec.yaml 文件: ${file.path}');
  
  final lines = file.readAsLinesSync();
  final updatedLines = <String>[];
  
  for (final line in lines) {
    if (line.startsWith('version:')) {
      updatedLines.add('version: $version');
    } else {
      updatedLines.add(line);
    }
  }
  
  file.writeAsStringSync(updatedLines.join('\n'));
  print('已成功更新 pubspec.yaml 中的版本号');
}
