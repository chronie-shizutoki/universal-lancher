import 'package:flutter/material.dart';

/// 服务项模型
class ServiceItem {
  final String id;
  final String name;
  final String url;
  final IconData icon;
  final Color color;
  final String? description;

  ServiceItem({
    required this.id,
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
    this.description,
  });

  /// 从JSON创建ServiceItem
  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['colorValue'] as int),
      description: json['description'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'description': description,
    };
  }

  /// 创建副本
  ServiceItem copyWith({
    String? id,
    String? name,
    String? url,
    IconData? icon,
    Color? color,
    String? description,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
