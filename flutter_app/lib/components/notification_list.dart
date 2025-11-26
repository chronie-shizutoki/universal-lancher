import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'notification_card.dart';

/// 通知列表组件
class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  // 通知API URL
  static const String NOTIFICATIONS_URL = 'https://universal-launcher.netlify.app/notifications.json';

  @override
  void initState() {
    super.initState();
    
    // 组件初始化时自动加载通知数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.loadNotifications(NOTIFICATIONS_URL);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '通知中心',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (notificationProvider.unreadCount > 0)
                  Text(
                    '${notificationProvider.unreadCount} 条未读',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          
          // 加载状态
          if (notificationProvider.isLoading)
            Expanded(
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // 错误状态
          if (!notificationProvider.isLoading && notificationProvider.errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      notificationProvider.errorMessage!, 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // 重新加载通知
                        notificationProvider.loadNotifications(NOTIFICATIONS_URL);
                      },
                      child: Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          
          // 空状态
          if (!notificationProvider.isLoading && notifications.isEmpty && notificationProvider.errorMessage == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '暂无通知',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          
          // 通知列表
          if (!notificationProvider.isLoading && notifications.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () {
                      // 标记为已读
                      notificationProvider.markAsRead(notification.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}