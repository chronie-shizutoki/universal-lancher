import 'package:flutter/material.dart';

/// 通知紧急程度枚举
enum NotificationPriority {
  /// 低优先级
  low,
  /// 中优先级
  medium,
  /// 高优先级
  high;

  /// 获取优先级对应的颜色
  Color get color {
    switch (this) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.high:
        return Colors.red;
    }
  }

  /// 获取优先级对应的文本
  String get text {
    switch (this) {
      case NotificationPriority.low:
        return '低';
      case NotificationPriority.medium:
        return '中';
      case NotificationPriority.high:
        return '高';
    }
  }

  /// 从字符串解析优先级
  static NotificationPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      default:
        return NotificationPriority.medium;
    }
  }
}

/// 通知项数据模型
class NotificationItem {
  /// 通知ID
  final String id;
  
  /// 通知标题
  final String title;
  
  /// 通知内容
  final String content;
  
  /// 通知紧急程度
  final NotificationPriority priority;
  
  /// 通知创建时间
  final DateTime createdAt;
  
  /// 是否已读
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
  });

  /// 从JSON创建通知项
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      priority: NotificationPriority.fromString(json['priority'] ?? 'medium'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// 创建已读版本的通知
  NotificationItem markAsRead() {
    return NotificationItem(
      id: id,
      title: title,
      content: content,
      priority: priority,
      createdAt: createdAt,
      isRead: true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}