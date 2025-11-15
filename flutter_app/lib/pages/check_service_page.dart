import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/service_item.dart';
import '../providers/service_provider.dart';
import '../providers/theme_provider.dart';

class CheckServicePage extends StatefulWidget {
  const CheckServicePage({super.key});

  @override
  State<CheckServicePage> createState() => _CheckServicePageState();
}

enum ServiceState { checking, running, stopped }

class ServiceCheckResult {
  final String id;
  final String name;
  final String url;
  final ServiceState state;
  final int responseTimeMs;
  final Map<String, dynamic>? healthData;

  ServiceCheckResult({
    required this.id,
    required this.name,
    required this.url,
    required this.state,
    required this.responseTimeMs,
    this.healthData,
  });
}

class _CheckServicePageState extends State<CheckServicePage> {
  final int _responseTimeThresholdMs = 2000;
  final TextEditingController _intervalController = TextEditingController(text: '60');
  Timer? _autoTimer;
  DateTime? _lastUpdate;
  bool _checkingAll = false;

  final Map<String, ServiceCheckResult> _results = {};

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
    final services = context.read<ServiceProvider>().services;
    setState(() {
      for (final s in services) {
        _results[s.id] = ServiceCheckResult(
          id: s.id,
          name: s.name,
          url: s.url,
          state: ServiceState.checking,
          responseTimeMs: 0,
          healthData: null,
        );
      }
    });
  }

  String _buildCheckUrl(ServiceItem s) {
    final uri = Uri.parse(s.url);
    final port = uri.hasPort ? uri.port : 0;
    if (port == 3010 || port == 5000) {
      return s.url.endsWith('/') ? '${s.url}api/health' : '${s.url}/api/health';
    }
    return s.url;
  }

  Future<ServiceCheckResult> _checkService(ServiceItem s) async {
    final checkUrl = _buildCheckUrl(s);
    final sw = Stopwatch()..start();
    Map<String, dynamic>? health;
    bool ok = false;

    try {
      final resp = await http
          .get(Uri.parse(checkUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (checkUrl.endsWith('/api/health')) {
          try {
            health = jsonDecode(resp.body) as Map<String, dynamic>;
            final status = health['status'];
            ok = status == 'OK' || status == 'healthy';
          } catch (_) {
            ok = true;
          }
        } else {
          ok = true;
        }
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
      healthData: health,
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
          healthData: null,
        );
      }
    });

    final services = context.read<ServiceProvider>().services;
    final futures = services.map(_checkService);
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
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    switch (s) {
      case ServiceState.running:
        return isDark ? const Color(0xFF1B3A2F) : const Color(0xFFE8F5E9);
      case ServiceState.stopped:
        return isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE);
      case ServiceState.checking:
        return isDark ? const Color(0xFF3D321F) : const Color(0xFFFFF8E1);
    }
  }

  String _statusText(ServiceState s, Map<String, dynamic>? health) {
    switch (s) {
      case ServiceState.running:
        return '运行正常';
      case ServiceState.stopped:
        final status = health != null ? health['status'] : null;
        return status != 'OK' ? '状态异常' : '响应超时';
      case ServiceState.checking:
        return '检查中...';
    }
  }

  Widget _buildHealthDetails(Map<String, dynamic> health) {
    final items = <Widget>[];
    final textStyle = const TextStyle(fontSize: 13, color: Colors.grey);

    final version = health['version'];
    if (version != null) {
      items.add(Text('版本：$version', style: textStyle));
    }

    final uptimeRaw = health['uptime'];
    if (uptimeRaw != null) {
      final uptime = int.tryParse('$uptimeRaw') ?? 0;
      final h = uptime ~/ 3600;
      final m = (uptime % 3600) ~/ 60;
      final s = uptime % 60;
      items.add(Text('运行时间：$h时$m分$s秒', style: textStyle));
    }

    if (health['database'] != null) {
      final db = health['database'] == 'healthy' ? '健康' : '${health['database']}';
      items.add(Text('数据库：$db', style: textStyle));
    } else if (health['services'] is Map && (health['services'] as Map)['database'] is Map) {
      final dbMap = (health['services'] as Map)['database'] as Map;
      final status = dbMap['status'];
      final db = status == 'connected' ? '已连接' : '$status';
      items.add(Text('数据库：$db', style: textStyle));
    }

    if (health['memory_usage'] is Map) {
      final mu = health['memory_usage'] as Map;
      final rssMb = mu['rss_mb'];
      final rss = mu['rss'];
      if (rssMb != null) {
        items.add(Text('内存使用：$rssMb MB', style: textStyle));
      } else if (rss != null) {
        items.add(Text('内存使用：$rss B', style: textStyle));
      }
    } else if (health['resources'] is Map && (health['resources'] as Map)['memory'] is Map) {
      final mem = (health['resources'] as Map)['memory'] as Map;
      final heapUsed = mem['heapUsed'];
      if (heapUsed != null) {
        items.add(Text('内存使用：$heapUsed', style: textStyle));
      }
    }

    if (health['service'] != null) {
      items.add(Text('服务名称：${health['service']}', style: textStyle));
    }

    if (health['resources'] is Map && (health['resources'] as Map)['cpu'] is Map) {
      final cpu = (health['resources'] as Map)['cpu'] as Map;
      final usage = cpu['usagePercent'];
      final model = cpu['model'];
      final count = cpu['count'];
      if (usage != null) {
        items.add(Text('CPU使用率：$usage', style: textStyle));
      }
      if (model != null && count != null) {
        items.add(Text('CPU型号：$model ($count核心)', style: textStyle));
      } else if (model != null) {
        items.add(Text('CPU型号：$model', style: textStyle));
      } else if (count != null) {
        items.add(Text('CPU核心数：$count', style: textStyle));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务状态监控'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
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
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final s = services[index];
                          final r = _results[s.id];
                          final state = r?.state ?? ServiceState.checking;
                          final health = r?.healthData;
                          return _ServiceCard(
                            title: s.name,
                            urlText: _buildCheckUrl(s),
                            state: state,
                            responseTimeMs: r?.responseTimeMs ?? 0,
                            health: health,
                            color: s.color,
                            context: context,
                          );
                        },
                      )
                    : ListView.separated(
                        itemCount: services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = services[index];
                          final r = _results[s.id];
                          final state = r?.state ?? ServiceState.checking;
                          final health = r?.healthData;
                          return _ServiceCard(
                            title: s.name,
                            urlText: _buildCheckUrl(s),
                            state: state,
                            responseTimeMs: r?.responseTimeMs ?? 0,
                            health: health,
                            color: s.color,
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
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
  final Map<String, dynamic>? health;
  final Color color;
  final BuildContext context;

  const _ServiceCard({
    required this.title,
    required this.urlText,
    required this.state,
    required this.responseTimeMs,
    required this.health,
    required this.color,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(this.context);
    final isDark = Provider.of<ThemeProvider>(this.context).isDarkMode;
    final borderColor = _borderColor(state);
    final bgColor = _bgColor(state);
    final statusText = _statusText(state, health);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
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
        const SizedBox(height: 6),
        Text(
          urlText, 
          style: TextStyle(
            fontSize: 14, 
            color: isDark ? Colors.white70 : Colors.grey
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
        const SizedBox(height: 6),
        Text(
          '响应时间：${responseTimeMs > 0 ? '$responseTimeMs ms' : '--'}', 
          style: TextStyle(
            fontSize: 14, 
            color: isDark ? Colors.white70 : Colors.grey
          )
        ),
        if (health != null) ...[
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 10),
          _buildHealthDetailsWidget(health!),
        ],
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

  Color _bgColor(ServiceState s) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
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

  String _statusText(ServiceState s, Map<String, dynamic>? health) {
    switch (s) {
      case ServiceState.running:
        return '运行正常';
      case ServiceState.stopped:
        final status = health != null ? health['status'] : null;
        return status != 'OK' ? '状态异常' : '响应超时';
      case ServiceState.checking:
        return '检查中...';
    }
  }

  Widget _buildHealthDetailsWidget(Map<String, dynamic> health) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textStyle = TextStyle(
      fontSize: 13, 
      color: isDark ? Colors.white70 : Colors.grey
    );
    final children = <Widget>[];

    final version = health['version'];
    if (version != null) children.add(Text('版本：$version', style: textStyle));

    final uptimeRaw = health['uptime'];
    if (uptimeRaw != null) {
      final uptime = int.tryParse('$uptimeRaw') ?? 0;
      final h = uptime ~/ 3600;
      final m = (uptime % 3600) ~/ 60;
      final s = uptime % 60;
      children.add(Text('运行时间：$h时$m分$s秒', style: textStyle));
    }

    if (health['database'] != null) {
      final db = health['database'] == 'healthy' ? '健康' : '${health['database']}';
      children.add(Text('数据库：$db', style: textStyle));
    } else if (health['services'] is Map && (health['services'] as Map)['database'] is Map) {
      final dbMap = (health['services'] as Map)['database'] as Map;
      final status = dbMap['status'];
      final db = status == 'connected' ? '已连接' : '$status';
      children.add(Text('数据库：$db', style: textStyle));
    }

    if (health['memory_usage'] is Map) {
      final mu = health['memory_usage'] as Map;
      final rssMb = mu['rss_mb'];
      final rss = mu['rss'];
      if (rssMb != null) {
        children.add(Text('内存使用：$rssMb MB', style: textStyle));
      } else if (rss != null) {
        children.add(Text('内存使用：$rss B', style: textStyle));
      }
    } else if (health['resources'] is Map && (health['resources'] as Map)['memory'] is Map) {
      final mem = (health['resources'] as Map)['memory'] as Map;
      final heapUsed = mem['heapUsed'];
      if (heapUsed != null) {
        children.add(Text('内存使用：$heapUsed', style: textStyle));
      }
    }

    if (health['service'] != null) {
      children.add(Text('服务名称：${health['service']}', style: textStyle));
    }

    if (health['resources'] is Map && (health['resources'] as Map)['cpu'] is Map) {
      final cpu = (health['resources'] as Map)['cpu'] as Map;
      final usage = cpu['usagePercent'];
      final model = cpu['model'];
      final count = cpu['count'];
      if (usage != null) {
        children.add(Text('CPU使用率：$usage', style: textStyle));
      }
      if (model != null && count != null) {
        children.add(Text('CPU型号：$model ($count核心)', style: textStyle));
      } else if (model != null) {
        children.add(Text('CPU型号：$model', style: textStyle));
      } else if (count != null) {
        children.add(Text('CPU核心数：$count', style: textStyle));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}