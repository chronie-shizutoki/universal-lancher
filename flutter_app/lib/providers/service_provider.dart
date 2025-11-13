import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_item.dart';

/// 服务管理Provider
class ServiceProvider extends ChangeNotifier {
  List<ServiceItem> _services = [];
  static const String _storageKey = 'service_items';

  List<ServiceItem> get services => _services;

  ServiceProvider() {
    _loadServices();
  }

  /// 加载服务列表
  Future<void> _loadServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? servicesJson = prefs.getString(_storageKey);

      if (servicesJson != null && servicesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(servicesJson);
        _services = decoded.map((item) => ServiceItem.fromJson(item)).toList();
      } else {
        // 如果没有保存的数据，使用默认服务列表
        _services = _getDefaultServices();
        await _saveServices();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('加载服务列表失败: $e');
      }
      // 出错时使用默认列表
      _services = _getDefaultServices();
      notifyListeners();
    }
  }

  /// 保存服务列表
  Future<void> _saveServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_services.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('保存服务列表失败: $e');
      }
    }
  }

  /// 获取默认服务列表（基于原项目）
  List<ServiceItem> _getDefaultServices() {
    return [
      ServiceItem(
        id: 'accounting',
        name: '记账',
        url: 'http://192.168.0.197:3010',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF667eea),
        description: '家庭记账系统',
      ),
      ServiceItem(
        id: 'accounting_intl',
        name: '记账（国际版）',
        url: 'http://192.168.0.197:3000',
        icon: Icons.language,
        color: const Color(0xFF764ba2),
        description: '国际版记账系统',
      ),
      ServiceItem(
        id: 'cashflow',
        name: '金流',
        url: 'http://192.168.0.197:3100',
        icon: Icons.attach_money,
        color: const Color(0xFFf093fb),
        description: '金流管理系统',
      ),
      ServiceItem(
        id: 'inventory',
        name: '库存',
        url: 'http://192.168.0.197:5000',
        icon: Icons.inventory,
        color: const Color(0xFF4facfe),
        description: '库存管理系统',
      ),
    ];
  }

  /// 添加服务
  Future<void> addService(ServiceItem service) async {
    _services.add(service);
    await _saveServices();
    notifyListeners();
  }

  /// 更新服务
  Future<void> updateService(String id, ServiceItem updatedService) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index != -1) {
      _services[index] = updatedService;
      await _saveServices();
      notifyListeners();
    }
  }

  /// 删除服务
  Future<void> deleteService(String id) async {
    _services.removeWhere((s) => s.id == id);
    await _saveServices();
    notifyListeners();
  }

  /// 重置为默认服务
  Future<void> resetToDefault() async {
    _services = _getDefaultServices();
    await _saveServices();
    notifyListeners();
  }
}
