import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/theme_provider.dart';

class RateCalculatorPage extends StatefulWidget {
  final VoidCallback? onBack;

  const RateCalculatorPage({super.key, this.onBack});

  @override
  State<RateCalculatorPage> createState() => _RateCalculatorPageState();
}

class _RateCalculatorPageState extends State<RateCalculatorPage> {
  final TextEditingController _tokenRateController = TextEditingController();
  final TextEditingController _cnyRateController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _cnyController = TextEditingController();

  double? _tokenRate;
  double? _cnyRate;
  bool _updating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedRates();
    _fetchLatestRates();
  }

  @override
  void dispose() {
    _tokenRateController.dispose();
    _cnyRateController.dispose();
    _usdController.dispose();
    _tokenController.dispose();
    _cnyController.dispose();
    super.dispose();
  }

  // 从本地存储加载汇率
  Future<void> _loadSavedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTokenRate = prefs.getDouble('tokenRate');
    final savedCnyRate = prefs.getDouble('cnyRate');
    
    if (savedTokenRate != null && savedCnyRate != null) {
      setState(() {
        _tokenRate = savedTokenRate;
        _cnyRate = savedCnyRate;
        _tokenRateController.text = savedTokenRate.toString();
        _cnyRateController.text = savedCnyRate.toString();
      });
    }
  }

  // 保存汇率到本地存储
  Future<void> _saveRates(double tokenRate, double cnyRate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tokenRate', tokenRate);
    await prefs.setDouble('cnyRate', cnyRate);
  }

  // 从API获取最新汇率
  Future<void> _fetchLatestRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.197:3200/api/exchange-rates/latest'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tokenRate = data['data']['rate'] as double;
          setState(() {
            _tokenRateController.text = tokenRate.toString();
            _tokenRate = tokenRate;
          });
          
          // 同时保存到本地存储
          if (_cnyRate != null) {
            await _saveRates(tokenRate, _cnyRate!);
          }
          
          if (!mounted) return;
          
          ToastManager.showToast(
            context, 
            '已获取最新汇率：1美元 = $tokenRate 金流'
          );
        }
      }
    } catch (e) {
        // API请求失败，不做任何操作，保持现有汇率
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setRates() {
    final tokenRate = double.tryParse(_tokenRateController.text);
    final cnyRate = double.tryParse(_cnyRateController.text);

    if (tokenRate == null || cnyRate == null || tokenRate <= 0 || cnyRate <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('请输入有效的汇率值（大于0）'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
          ],
        ),
      );
      return;
    }

    setState(() {
      _tokenRate = tokenRate;
      _cnyRate = cnyRate;
      _usdController.clear();
      _tokenController.clear();
      _cnyController.clear();
    });

    // 保存汇率到本地存储
    _saveRates(tokenRate, cnyRate);

    ToastManager.showToast(
      context, 
      '汇率设置成功：1美元 = $_tokenRate 金流，1美元 = $_cnyRate 人民币'
    );
  }

  void _onUsdChanged(String v) {
    if (_updating) return;
    final rateT = _tokenRate;
    final rateC = _cnyRate;
    if (rateT == null || rateC == null) {
      ToastManager.showToast(context, '请先设置汇率');
      _usdController.clear();
      return;
    }
    final usd = double.tryParse(v);
    if (usd == null || usd < 0) {
      _updating = true;
      _tokenController.clear();
      _cnyController.clear();
      _updating = false;
      return;
    }
    _updating = true;
    _tokenController.text = (usd * rateT).toStringAsFixed(4);
    _cnyController.text = (usd * rateC).toStringAsFixed(4);
    _updating = false;
  }

  void _onTokenChanged(String v) {
    if (_updating) return;
    final rateT = _tokenRate;
    final rateC = _cnyRate;
    if (rateT == null || rateC == null) {
      ToastManager.showToast(context, '请先设置汇率');
      _tokenController.clear();
      return;
    }
    final token = double.tryParse(v);
    if (token == null || token < 0) {
      _updating = true;
      _usdController.clear();
      _cnyController.clear();
      _updating = false;
      return;
    }
    _updating = true;
    final usd = token / rateT;
    _usdController.text = usd.toStringAsFixed(4);
    _cnyController.text = (usd * rateC).toStringAsFixed(4);
    _updating = false;
  }

  void _onCnyChanged(String v) {
    if (_updating) return;
    final rateT = _tokenRate;
    final rateC = _cnyRate;
    if (rateT == null || rateC == null) {
      ToastManager.showToast(context, '请先设置汇率');
      _cnyController.clear();
      return;
    }
    final cny = double.tryParse(v);
    if (cny == null || cny < 0) {
      _updating = true;
      _usdController.clear();
      _tokenController.clear();
      _updating = false;
      return;
    }
    _updating = true;
    final usd = cny / rateC;
    _usdController.text = usd.toStringAsFixed(4);
    _tokenController.text = (usd * rateT).toStringAsFixed(4);
    _updating = false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('汇率计算器'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 返回计算器选择页面
            widget.onBack?.call();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2d2d2d), const Color(0xFF1a1a1a)]
                : [const Color(0xFFf5f7fa), const Color(0xFFc3cfe2)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 主容器 - 液态玻璃效果
            _GlassContainer(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '货币兑换计算器',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // 汇率设置部分
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '汇率设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: '1美元 = ? 金流',
                              controller: _tokenRateController,
                              hint: '输入金流数量',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LabeledField(
                              label: '1美元 = ? 人民币',
                              controller: _cnyRateController,
                              hint: '输入人民币数量',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: _GlassButton(
                          onPressed: _setRates,
                          isLoading: _isLoading,
                          text: '设置汇率',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    thickness: 1,
                  ),
                  const SizedBox(height: 25),
                  
                  // 货币兑换部分
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '货币兑换',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CurrencyRow(
                        label: '美元 (USD)',
                        symbol: '\$',
                        controller: _usdController,
                        onChanged: _onUsdChanged,
                      ),
                      const SizedBox(height: 15),
                      _CurrencyRow(
                        label: '金流',
                        symbol: 'T',
                        controller: _tokenController,
                        onChanged: _onTokenChanged,
                      ),
                      const SizedBox(height: 15),
                      _CurrencyRow(
                        label: '人民币 (CNY)',
                        symbol: '¥',
                        controller: _cnyController,
                        onChanged: _onCnyChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    thickness: 1,
                  ),
                  const SizedBox(height: 25),
                  
                  // 使用说明部分
                  _GlassContainer(
                    padding: const EdgeInsets.all(15),
                    borderRadius: 12,
                    borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    backgroundColor: isDark
                        ? const Color(0xFF304159).withValues(alpha: 0.7)
                        : const Color(0xFFE8F4FC).withValues(alpha: 0.7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用说明：',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. 首先在"汇率设置"区域输入1美元兑换的金流数量和人民币数量',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '2. 点击"设置汇率"按钮确认汇率',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '3. 在"货币兑换"区域的任意一个输入框中输入金额，其他两个输入框会自动计算对应的金额',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 底部安全占位区域
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// 液态玻璃容器组件
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark
            ? const Color(0xFF1a1a1a).withValues(alpha: 0.7)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (isDark
              ? const Color(0xFF555555).withValues(alpha: 0.5)
              : const Color(0xFFe1e5e9).withValues(alpha: 0.5)),
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
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;

  const _GlassButton({
    required this.onPressed,
    required this.isLoading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _LabeledField({required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2d2d2d).withValues(alpha: 0.7)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF555555).withValues(alpha: 0.5)
                : const Color(0xFFe1e5e9).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(15),
          ),
        ),
      ),
    ]);
  }
}

class _CurrencyRow extends StatelessWidget {
  final String label;
  final String symbol;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CurrencyRow({
    required this.label,
    required this.symbol,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2d2d2d).withValues(alpha: 0.7)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF555555).withValues(alpha: 0.5)
              : const Color(0xFFe1e5e9).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          symbol,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ]),
    );
  }
}

// 自定义Toast组件
class _CustomToast extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CustomToast({required this.message, required this.duration, required this.onDismissed});

  @override
  State<_CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<_CustomToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 淡入淡出动画
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // 滑动动画
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // 启动进入动画
    _controller.forward();

    // 显示一段时间后开始退出动画
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismissed();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: _GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                borderRadius: 12,
                backgroundColor: isDark
                    ? const Color(0xFF333333).withValues(alpha: 0.8)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Toast工具类
class ToastManager {
  static void showToast(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomToast(
        message: message, 
        duration: duration,
        onDismissed: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}