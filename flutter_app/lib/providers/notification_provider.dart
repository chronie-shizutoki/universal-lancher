import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

/// 通知服务提供者
class NotificationProvider extends ChangeNotifier {
  /// 通知列表
  List<NotificationItem> _notifications = [];
  
  /// 是否正在加载
  bool _isLoading = false;
  
  /// 错误信息
  String? _errorMessage;
  
  /// 获取通知列表（按优先级和时间排序）
  List<NotificationItem> get notifications {
    final sorted = List<NotificationItem>.from(_notifications);
    // 首先按优先级排序（高优先级在前），然后按时间排序（最新的在前）
    sorted.sort((a, b) {
      if (a.priority.index != b.priority.index) {
        return b.priority.index.compareTo(a.priority.index);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
  
  /// 获取未读通知数量
  int get unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }
  
  /// 获取最新通知（用于显示在胶囊中）
  NotificationItem? get latestNotification {
    if (_notifications.isEmpty) return null;
    return notifications.first;
  }
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 错误信息
  String? get errorMessage => _errorMessage;
  
  /// 从URL加载通知
  Future<void> loadNotifications(String url) async {
    _isLoading = true;
    _errorMessage = null;
    _notifications.clear(); // 清空现有数据
    notifyListeners();
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notifications = data.map((item) => NotificationItem.fromJson(item)).toList();
      } else {
        _errorMessage = '加载失败';
      }
    } catch (error) {
      _errorMessage = '加载失败';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 标记通知为已读
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((item) => item.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].markAsRead();
      notifyListeners();
    }
  }
}