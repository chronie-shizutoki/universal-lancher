import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CheckServicePage extends StatefulWidget {
  const CheckServicePage({super.key});

  @override
  State<CheckServicePage> createState() => _CheckServicePageState();
}

enum ServiceState { checking, running, stopped }

class ServiceItem {
  final String id;
  final String name;
  final String url;

  ServiceItem({
    required this.id,
    required this.name,
    required this.url,
  });
}

class ServiceCheckResult {
  final String id;
  final String name;
  final String url;
  final ServiceState state;
  final int responseTimeMs;

  ServiceCheckResult({
    required this.id,
    required this.name,
    required this.url,
    required this.state,
    required this.responseTimeMs,
  });
}

class _CheckServicePageState extends State<CheckServicePage> {
  final int _responseTimeThresholdMs = 2000;
  final TextEditingController _intervalController = TextEditingController(text: '60');
  Timer? _autoTimer;
  DateTime? _lastUpdate;
  bool _checkingAll = false;

  final Map<String, ServiceCheckResult> _results = {};
  
  // 固定的服务列表
  final List<ServiceItem> _services = [
    ServiceItem(id: '1', name: '家庭财务管理系统（国际版）', url: 'http://192.168.0.197:3000'),
    ServiceItem(id: '2', name: '家庭记账本', url: 'http://192.168.0.197:3010/api/lite'),
    ServiceItem(id: '3', name: '金流', url: 'http://192.168.0.197:3100'),
    ServiceItem(id: '4', name: '库存管理', url: 'http://192.168.0.197:5000/api/health'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _checkAllServices();
      _setupAutoCheck(int.parse(_intervalController.text));
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _initializeServices() {
    setState(() {
      for (final s in _services) {
        _results[s.id] = ServiceCheckResult(
          id: s.id,
          name: s.name,
          url: s.url,
          state: ServiceState.checking,
          responseTimeMs: 0,
        );
      }
    });
  }

  String _buildCheckUrl(ServiceItem s) {
    return s.url;
  }

  Future<ServiceCheckResult> _checkService(ServiceItem s) async {
    final checkUrl = _buildCheckUrl(s);
    final sw = Stopwatch()..start();
    bool ok = false;

    try {
      final resp = await http
          .get(Uri.parse(checkUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ok = true;
      }
    } catch (_) {}

    sw.stop();
    final rt = sw.elapsedMilliseconds;
    final state = ok && rt <= _responseTimeThresholdMs ? ServiceState.running : ServiceState.stopped;

    return ServiceCheckResult(
      id: s.id,
      name: s.name,
      url: checkUrl,
      state: state,
      responseTimeMs: rt,
    );
  }

  Future<void> _checkAllServices() async {
    if (_checkingAll) return;
    setState(() {
      _checkingAll = true;
      for (final id in _results.keys) {
        final current = _results[id]!;
        _results[id] = ServiceCheckResult(
          id: current.id,
          name: current.name,
          url: current.url,
          state: ServiceState.checking,
          responseTimeMs: 0,
        );
      }
    });

    final futures = _services.map(_checkService);
    final results = await Future.wait(futures);
    setState(() {
      for (final r in results) {
        _results[r.id] = r;
      }
      _lastUpdate = DateTime.now();
      _checkingAll = false;
    });
  }

  void _setupAutoCheck(int seconds) {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      _checkAllServices();
    });
  }

  Color _borderColor(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return const Color(0xFF4CAF50);
      case ServiceState.stopped:
        return const Color(0xFFF44336);
      case ServiceState.checking:
        return const Color(0xFFFFC107);
    }
  }

  Color _bgColor(ServiceState s, BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    switch (s) {
      case ServiceState.running:
        return isDark ? const Color(0xFF1B3A2F) : const Color(0xFFE8F5E9);
      case ServiceState.stopped:
        return isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE);
      case ServiceState.checking:
        return isDark ? const Color(0xFF3D321F) : const Color(0xFFFFF8E1);
    }
  }

  String _statusText(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return '运行正常';
      case ServiceState.stopped:
        return '状态异常';
      case ServiceState.checking:
        return '检查中...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 1200;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: isLarge
                ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      final r = _results[s.id];
                      final state = r?.state ?? ServiceState.checking;
                      return _ServiceCard(
                        title: s.name,
                        urlText: _buildCheckUrl(s),
                        state: state,
                        responseTimeMs: r?.responseTimeMs ?? 0,
                        context: context,
                      );
                    },
                  )
                : ListView.separated(
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      final r = _results[s.id];
                      final state = r?.state ?? ServiceState.checking;
                      return _ServiceCard(
                        title: s.name,
                        urlText: _buildCheckUrl(s),
                        state: state,
                        responseTimeMs: r?.responseTimeMs ?? 0,
                        context: context,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _checkingAll ? null : _checkAllServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(_checkingAll ? '检查中...' : '立即检查所有服务'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '自动检查间隔（秒）：',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onSubmitted: (v) {
                    final seconds = int.tryParse(v) ?? 5;
                    final clamped = seconds < 5 ? 5 : seconds;
                    _intervalController.text = '$clamped';
                    _setupAutoCheck(clamped);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _lastUpdate == null
                ? '最后更新：未检查'
                : '最后更新：${_formatDateTime(_lastUpdate!)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
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

class _ServiceCard extends StatelessWidget {
  final String title;
  final String urlText;
  final ServiceState state;
  final int responseTimeMs;
  final BuildContext context;

  const _ServiceCard({
    required this.title,
    required this.urlText,
    required this.state,
    required this.responseTimeMs,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(this.context);
    final brightness = MediaQuery.of(this.context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    final borderColor = _borderColor(state);
    final bgColor = _bgColor(state, this.context);
    final statusText = _statusText(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface
          )
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusBg(state),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusText, 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: _statusFg(state)
            )
          ),
        ),
      ]),
    );
  }

  Color _borderColor(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return const Color(0xFF4CAF50);
      case ServiceState.stopped:
        return const Color(0xFFF44336);
      case ServiceState.checking:
        return const Color(0xFFFFC107);
    }
  }

  Color _bgColor(ServiceState s, BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    switch (s) {
      case ServiceState.running:
        return isDark ? const Color(0xFF1B3A2F) : const Color(0xFFE8F5E9);
      case ServiceState.stopped:
        return isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE);
      case ServiceState.checking:
        return isDark ? const Color(0xFF3D321F) : const Color(0xFFFFF8E1);
    }
  }

  Color _statusBg(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return const Color(0xFF4CAF50);
      case ServiceState.stopped:
        return const Color(0xFFF44336);
      case ServiceState.checking:
        return const Color(0xFFFFC107);
    }
  }

  Color _statusFg(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return Colors.white;
      case ServiceState.stopped:
        return Colors.white;
      case ServiceState.checking:
        return Colors.black87;
    }
  }

  String _statusText(ServiceState s) {
    switch (s) {
      case ServiceState.running:
        return '运行正常';
      case ServiceState.stopped:
        return '状态异常';
      case ServiceState.checking:
        return '检查中...';
    }
  }
}