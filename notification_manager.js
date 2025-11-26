const fs = require('fs');
const path = require('path');

/**
 * 通知管理器类
 * 用于管理notifications.json文件
 */
class NotificationManager {
  constructor(filePath = 'notifications.json') {
    this.filePath = path.resolve(filePath);
  }

  /**
   * 读取通知数据
   * @returns {Array} 通知列表
   */
  readNotifications() {
    try {
      if (!fs.existsSync(this.filePath)) {
        console.log(`文件 ${this.filePath} 不存在，将创建新文件`);
        fs.writeFileSync(this.filePath, JSON.stringify([], null, 2));
        return [];
      }

      const data = fs.readFileSync(this.filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error('读取通知数据失败:', error.message);
      return [];
    }
  }

  /**
   * 保存通知数据
   * @param {Array} notifications 通知列表
   * @returns {boolean} 是否保存成功
   */
  saveNotifications(notifications) {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(notifications, null, 2));
      return true;
    } catch (error) {
      console.error('保存通知数据失败:', error.message);
      return false;
    }
  }

  /**
   * 获取所有通知
   * @returns {Array} 通知列表
   */
  getAllNotifications() {
    return this.readNotifications();
  }

  /**
   * 根据ID获取通知
   * @param {string} id 通知ID
   * @returns {Object|null} 通知对象或null
   */
  getNotificationById(id) {
    const notifications = this.readNotifications();
    return notifications.find(notification => notification.id === id) || null;
  }

  /**
   * 添加新通知
   * @param {Object} notification 通知对象
   * @returns {Object|null} 添加的通知对象或null
   */
  addNotification(notification) {
    try {
      const notifications = this.readNotifications();
      
      // 确保有ID
      if (!notification.id) {
        notification.id = Date.now().toString();
      }
      
      // 确保有创建时间
      if (!notification.created_at) {
        notification.created_at = new Date().toISOString();
      }
      
      // 确保有已读状态
      if (notification.is_read === undefined) {
        notification.is_read = false;
      }
      
      // 确保有优先级
      if (!notification.priority) {
        notification.priority = 'low';
      }
      
      notifications.push(notification);
      
      if (this.saveNotifications(notifications)) {
        return notification;
      }
      return null;
    } catch (error) {
      console.error('添加通知失败:', error.message);
      return null;
    }
  }

  /**
   * 更新通知
   * @param {string} id 通知ID
   * @param {Object} updates 更新内容
   * @returns {Object|null} 更新后的通知对象或null
   */
  updateNotification(id, updates) {
    try {
      const notifications = this.readNotifications();
      const index = notifications.findIndex(notification => notification.id === id);
      
      if (index === -1) {
        console.log(`未找到ID为 ${id} 的通知`);
        return null;
      }
      
      // 更新通知
      notifications[index] = { ...notifications[index], ...updates };
      
      if (this.saveNotifications(notifications)) {
        return notifications[index];
      }
      return null;
    } catch (error) {
      console.error('更新通知失败:', error.message);
      return null;
    }
  }

  /**
   * 删除通知
   * @param {string} id 通知ID
   * @returns {boolean} 是否删除成功
   */
  deleteNotification(id) {
    try {
      const notifications = this.readNotifications();
      const initialLength = notifications.length;
      
      const filteredNotifications = notifications.filter(
        notification => notification.id !== id
      );
      
      if (filteredNotifications.length === initialLength) {
        console.log(`未找到ID为 ${id} 的通知`);
        return false;
      }
      
      return this.saveNotifications(filteredNotifications);
    } catch (error) {
      console.error('删除通知失败:', error.message);
      return false;
    }
  }

  /**
   * 标记通知为已读
   * @param {string} id 通知ID
   * @returns {boolean} 是否标记成功
   */
  markAsRead(id) {
    return this.updateNotification(id, { is_read: true }) !== null;
  }

  /**
   * 标记所有通知为已读
   * @returns {boolean} 是否标记成功
   */
  markAllAsRead() {
    try {
      const notifications = this.readNotifications();
      const updatedNotifications = notifications.map(notification => ({
        ...notification,
        is_read: true
      }));
      
      return this.saveNotifications(updatedNotifications);
    } catch (error) {
      console.error('标记所有通知为已读失败:', error.message);
      return false;
    }
  }

  /**
   * 获取未读通知数量
   * @returns {number} 未读通知数量
   */
  getUnreadCount() {
    const notifications = this.readNotifications();
    return notifications.filter(notification => !notification.is_read).length;
  }

  /**
   * 按优先级和时间排序通知
   * @param {Array} notifications 通知列表
   * @returns {Array} 排序后的通知列表
   */
  sortNotifications(notifications) {
    const priorityOrder = { high: 3, medium: 2, low: 1 };
    
    return [...notifications].sort((a, b) => {
      // 优先按优先级排序
      const priorityDiff = priorityOrder[b.priority] - priorityOrder[a.priority];
      if (priorityDiff !== 0) return priorityDiff;
      
      // 再按时间排序（最新的在前）
      return new Date(b.created_at) - new Date(a.created_at);
    });
  }

  /**
   * 获取排序后的通知列表
   * @returns {Array} 排序后的通知列表
   */
  getSortedNotifications() {
    const notifications = this.readNotifications();
    return this.sortNotifications(notifications);
  }

  /**
   * 获取最新的通知
   * @param {number} count 数量
   * @returns {Array} 最新的通知列表
   */
  getLatestNotifications(count = 3) {
    const notifications = this.readNotifications();
    return [...notifications]
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, count);
  }

  /**
   * 根据优先级筛选通知
   * @param {string} priority 优先级 ('low', 'medium', 'high')
   * @returns {Array} 筛选后的通知列表
   */
  getNotificationsByPriority(priority) {
    const notifications = this.readNotifications();
    return notifications.filter(notification => notification.priority === priority);
  }
}

// 如果直接运行脚本，则提供命令行接口
if (require.main === module) {
  const manager = new NotificationManager();
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('通知管理器命令行工具');
    console.log('用法:');
    console.log('  node notification_manager.js list                 - 列出所有通知');
    console.log('  node notification_manager.js add <title> <content> [priority] - 添加新通知');
    console.log('  node notification_manager.js delete <id>          - 删除通知');
    console.log('  node notification_manager.js mark-read <id>       - 标记通知为已读');
    console.log('  node notification_manager.js mark-all-read       - 标记所有通知为已读');
    console.log('  node notification_manager.js stats               - 显示通知统计信息');
  } else {
    const command = args[0];
    
    switch (command) {
      case 'list': {
        const notifications = manager.getSortedNotifications();
        console.log(JSON.stringify(notifications, null, 2));
        break;
      }
      
      case 'add': {
        if (args.length < 3) {
          console.log('错误: 需要提供标题和内容');
          break;
        }
        const title = args[1];
        const content = args[2];
        const priority = args[3] || 'low';
        
        const notification = manager.addNotification({
          title,
          content,
          priority,
          is_read: false,
          created_at: new Date().toISOString()
        });
        
        if (notification) {
          console.log('通知添加成功:', notification);
        } else {
          console.log('通知添加失败');
        }
        break;
      }
      
      case 'delete': {
        if (args.length < 2) {
          console.log('错误: 需要提供通知ID');
          break;
        }
        const id = args[1];
        
        if (manager.deleteNotification(id)) {
          console.log(`通知 ${id} 删除成功`);
        } else {
          console.log(`通知 ${id} 删除失败`);
        }
        break;
      }
      
      case 'mark-read': {
        if (args.length < 2) {
          console.log('错误: 需要提供通知ID');
          break;
        }
        const id = args[1];
        
        if (manager.markAsRead(id)) {
          console.log(`通知 ${id} 已标记为已读`);
        } else {
          console.log(`标记通知 ${id} 为已读失败`);
        }
        break;
      }
      
      case 'mark-all-read': {
        if (manager.markAllAsRead()) {
          console.log('所有通知已标记为已读');
        } else {
          console.log('标记所有通知为已读失败');
        }
        break;
      }
      
      case 'stats': {
        const notifications = manager.readNotifications();
        const unreadCount = manager.getUnreadCount();
        const highPriorityCount = notifications.filter(n => n.priority === 'high').length;
        const mediumPriorityCount = notifications.filter(n => n.priority === 'medium').length;
        const lowPriorityCount = notifications.filter(n => n.priority === 'low').length;
        
        console.log('通知统计信息:');
        console.log(`总通知数: ${notifications.length}`);
        console.log(`未读通知数: ${unreadCount}`);
        console.log(`已读通知数: ${notifications.length - unreadCount}`);
        console.log(`高优先级通知: ${highPriorityCount}`);
        console.log(`中优先级通知: ${mediumPriorityCount}`);
        console.log(`低优先级通知: ${lowPriorityCount}`);
        break;
      }
      
      default:
        console.log(`未知命令: ${command}`);
    }
  }
}

module.exports = NotificationManager;