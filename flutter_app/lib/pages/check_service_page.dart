import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CheckServicePage extends StatefulWidget {
  const CheckServicePage({super.key});

  @override
  State<CheckServicePage> createState() => _CheckServicePageState();
}

class ServiceInfo {
  final String id;
  final String name;
  final String url;

  ServiceInfo({
    required this.id,
    required this.name,
    required this.url,
  });
}

class ServiceStatus {
  final String serviceId;
  bool isHealthy;
  bool isChecking;

  ServiceStatus({
    required this.serviceId,
    this.isHealthy = false,
    this.isChecking = false,
  });
}

class _CheckServicePageState extends State<CheckServicePage> {
  // 固定的三个服务列表
  final List<ServiceInfo> _services = [
    ServiceInfo(
      id: '1',
      name: '家庭记账本',
      url: 'http://192.168.0.197:3010/api/health/lite',
    ),
    ServiceInfo(
      id: '2',
      name: '库存管理',
      url: 'http://192.168.0.197:5000/api/health',
    ),
    ServiceInfo(
      id: '3',
      name: '金流',
      url: 'http://192.168.0.197:3100',
    ),
  ];

  final Map<String, ServiceStatus> _statusMap = {};
  bool _checkingAll = false;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _initializeStatusMap();
    _checkAllServices();
  }

  void _initializeStatusMap() {
    for (final service in _services) {
      _statusMap[service.id] = ServiceStatus(serviceId: service.id);
    }
  }

  Future<void> _checkService(ServiceInfo service) async {
    setState(() {
      _statusMap[service.id]!.isChecking = true;
    });

    bool isHealthy = false;
    try {
      final response = await http.get(Uri.parse(service.url)).timeout(const Duration(seconds: 5));
      isHealthy = response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      isHealthy = false;
    }

    setState(() {
      _statusMap[service.id]!.isHealthy = isHealthy;
      _statusMap[service.id]!.isChecking = false;
    });
  }

  Future<void> _checkAllServices() async {
    if (_checkingAll) return;

    setState(() {
      _checkingAll = true;
      for (final service in _services) {
        _statusMap[service.id]!.isChecking = true;
      }
    });

    final futures = _services.map(_checkService);
    await Future.wait(futures);

    setState(() {
      _checkingAll = false;
      _lastUpdate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final service = _services[index];
                  final status = _statusMap[service.id]!;
                  return _buildServiceRow(service, status);
                },
              ),
            ),
            // 减少底部间距，让按钮和文字向上偏移
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _checkingAll ? null : _checkAllServices,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(_checkingAll ? '检查中...' : '立即检查'),
            ),
            if (_lastUpdate != null) ...[
              const SizedBox(height: 4),
              Text(
                '最后检查时间：${_formatDateTime(_lastUpdate!)}',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 14,
                ),
              ),
            ],
            // 增加底部安全间距，确保内容不被底部导航栏遮挡
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(ServiceInfo service, ServiceStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.url,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          status.isChecking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  status.isHealthy ? Icons.check_circle : Icons.cancel,
                  color: status.isHealthy ? Colors.green : Colors.red,
                  size: 24,
                ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}