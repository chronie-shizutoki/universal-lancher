import 'package:flutter/material.dart';
import '../models/notification_model.dart';

/// 通知胶囊组件
class NotificationPill extends StatelessWidget {
  /// 最新通知
  final NotificationItem? notification;
  
  /// 点击事件回调
  final VoidCallback onTap;

  const NotificationPill({
    super.key,
    this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (notification == null) {
      // 无通知时的状态
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications,
                size: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '暂无通知',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 限制通知内容为30个字符
    String limitedContent = notification!.content.length > 30
        ? '${notification!.content.substring(0, 30)}...'
        : notification!.content;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: notification!.isRead
              ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)
              : notification!.priority.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification!.isRead
                ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                : notification!.priority.color.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 优先级图标
            if (!notification!.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification!.priority.color,
                ),
                margin: const EdgeInsets.only(right: 8),
              ),
            
            // 通知内容
            Text(
              limitedContent,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: notification!.isRead ? FontWeight.normal : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}