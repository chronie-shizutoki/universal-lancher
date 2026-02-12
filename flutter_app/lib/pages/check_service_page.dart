import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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

// 液态玻璃容器组件
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1a1a1a).withValues(alpha: 0.7)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF555555).withValues(alpha: 0.5)
              : const Color(0xFFe1e5e9).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 液态玻璃按钮组件
class _GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const _GlassButton({
    this.onPressed,
    required this.isLoading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CheckServicePageState extends State<CheckServicePage> {
  // 固定的服务列表
  final List<ServiceInfo> _services = [
    ServiceInfo(
      id: '1',
      name: '家庭记账本',
      url: 'http://192.168.0.197:3010/api/health/lite',
    ),
    ServiceInfo(
      id: '2',
      name: '金流',
      url: 'http://192.168.0.197:3100',
    )
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;

    return Scaffold(
      body: Center(
        child: Container(
          width: isLargeScreen ? screenWidth * 0.8 : null,
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
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
                const SizedBox(height: 4),
                _GlassButton(
                  onPressed: _checkingAll ? null : _checkAllServices,
                  isLoading: _checkingAll,
                  text: _checkingAll ? '检查中...' : '立即检查',
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
                const SizedBox(height: 16),
                _GlassButton(
                  onPressed: () => Navigator.of(context).pop(),
                  isLoading: false,
                  text: '返回',
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceRow(ServiceInfo service, ServiceStatus status) {
    return _GlassContainer(
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