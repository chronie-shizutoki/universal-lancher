import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/theme_provider.dart';

class RateCalculatorPage extends StatefulWidget {
  const RateCalculatorPage({super.key});

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
          final tokenRate = data['rate']['rate'] as double;
          setState(() {
            _tokenRateController.text = tokenRate.toString();
            _tokenRate = tokenRate;
          });
          
          // 同时保存到本地存储
          if (_cnyRate != null) {
            await _saveRates(tokenRate, _cnyRate!);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已获取最新汇率：1美元 = $tokenRate 金流')),
          );
        }
      }
    } catch (e) {
      // API请求失败，不做任何操作，保持现有汇率
      print('获取汇率失败: $e');
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('汇率设置成功：1美元 = $_tokenRate 金流，1美元 = $_cnyRate 人民币')),
    );
  }

  void _onUsdChanged(String v) {
    if (_updating) return;
    final rateT = _tokenRate;
    final rateC = _cnyRate;
    if (rateT == null || rateC == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先设置汇率')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先设置汇率')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先设置汇率')));
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
    return ListView(
      padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('汇率设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _LabeledField(label: '1美元 = ? 金流', controller: _tokenRateController, hint: '输入金流数量')),
                  const SizedBox(width: 16),
                  Expanded(child: _LabeledField(label: '1美元 = ? 人民币', controller: _cnyRateController, hint: '输入人民币数量')),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setRates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('设置汇率'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('货币兑换', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 16),
                _CurrencyRow(label: '美元 (USD)', symbol: '\$', controller: _usdController, onChanged: _onUsdChanged),
                const SizedBox(height: 12),
                _CurrencyRow(label: '金流', symbol: 'T', controller: _tokenController, onChanged: _onTokenChanged),
                const SizedBox(height: 12),
                _CurrencyRow(label: '人民币 (CNY)', symbol: '¥', controller: _cnyController, onChanged: _onCnyChanged),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2B3C) : const Color(0xFFE8F4FC),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
              ),
              padding: const EdgeInsets.all(16),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('使用说明：', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('1. 先输入并设置汇率'),
                Text('2. 点击“设置汇率”确认'),
                Text('3. 在任意一个输入框输入金额，其他两项自动计算'),
              ]),
            ),
            // 底部安全占位区域，确保内容不被底部导航栏遮挡
            const SizedBox(height: 60)
          ],
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Text(symbol, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ]),
    );
  }
}