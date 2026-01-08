import 'package:flutter/material.dart';
import 'price_comparison_page.dart';
import 'rate_calculator_page.dart';

class CalculatorSelectionPage extends StatelessWidget {
  final void Function(Widget page)? onCalculatorSelected;
  final void Function()? onBack;

  const CalculatorSelectionPage({super.key, this.onCalculatorSelected, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('计算器'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择计算器类型',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildCalculatorCard(
                      context,
                      title: '价格比较器',
                      description: '比较不同商品的单位价格，选择最划算的选项',
                      icon: Icons.price_change_outlined,
                      onTap: () {
                        if (onCalculatorSelected != null) {
                          // 使用AnimatedSwitcher添加过渡动画
                          onCalculatorSelected!(AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: PriceComparisonPage(onBack: () {
                              onCalculatorSelected!(this);
                            }),
                          ));
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PriceComparisonPage()),
                          );
                        }
                      },
                    ),
                    _buildCalculatorCard(
                      context,
                      title: '汇率计算器',
                      description: '进行不同货币之间的汇率转换',
                      icon: Icons.currency_exchange_outlined,
                      onTap: () {
                        if (onCalculatorSelected != null) {
                          // 使用AnimatedSwitcher添加过渡动画
                          onCalculatorSelected!(AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: RateCalculatorPage(onBack: () {
                              onCalculatorSelected!(this);
                            }),
                          ));
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RateCalculatorPage()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context,
    {
      required String title,
      required String description,
      required IconData icon,
      required Function() onTap,
    }
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}