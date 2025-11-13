import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_item.dart';
import '../providers/service_provider.dart';
import 'webview_page.dart';
import 'edit_service_page.dart';
import 'check_service_page.dart';
import 'rate_calculator_page.dart';

/// 主页面
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final titleSize = isSmall ? 24.0 : 28.0;
    final subtitleSize = isSmall ? 12.0 : 14.0;
    final headerIconSize = isSmall ? 60.0 : 80.0;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea).withValues(alpha: 0.1),
              const Color(0xFF764ba2).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 标题栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // 应用图标和标题
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            isSmall
                                ? Column(
                                    children: [
                                      Image.asset(
                                        'assets/icons/app_icon.png',
                                        width: headerIconSize,
                                        height: headerIconSize,
                                      ),
                                      const SizedBox(height: 12),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '统一启动器',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF667eea),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '请选择一个服务开始',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: subtitleSize,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/app_icon.png',
                                        width: headerIconSize,
                                        height: headerIconSize,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '统一启动器',
                                                style: TextStyle(
                                                  fontSize: titleSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF667eea),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '请选择一个服务开始',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: subtitleSize,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckServicePage(),
                                ),
                              );
                            },
                            icon: Icon(Icons.health_and_safety, size: isSmall ? 18 : 20),
                            label: const Text(
                              '服务状态监控',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RateCalculatorPage(),
                                ),
                              );
                            },
                            icon: Icon(Icons.currency_exchange, size: isSmall ? 18 : 20),
                            label: const Text(
                              '货币兑换计算器',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF764ba2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 服务网格
              Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  final services = serviceProvider.services;
                  
                  if (services.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '暂无服务',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final crossAxisCount = screenWidth < 600 ? 2 : 3;
                  final childAspect = screenWidth < 340
                      ? 0.8
                      : (screenWidth < 380 ? 0.9 : (screenWidth < 480 ? 1.0 : 1.2));
                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspect,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _ServiceCard(service: services[index]);
                        },
                        childCount: services.length,
                      ),
                    ),
                  );
                },
              ),
              
              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditServicePage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('添加服务'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// 服务卡片组件
class _ServiceCard extends StatelessWidget {
  final ServiceItem service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(
              title: service.name,
              url: service.url,
            ),
          ),
        );
      },
      onLongPress: () {
        _showServiceOptions(context);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              service.color,
              service.color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: service.color.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewPage(
                    title: service.name,
                    url: service.url,
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(isSmall ? 16.0 : 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    service.icon,
                    size: isSmall ? 42 : 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: isSmall ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑服务'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditServicePage(service: service),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除服务', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除「${service.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<ServiceProvider>().deleteService(service.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除「${service.name}」')),
                );
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
