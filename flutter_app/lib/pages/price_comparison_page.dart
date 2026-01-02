import 'package:flutter/material.dart';
import 'dart:math';
import '../data/unit_conversion.dart';
import '../data/currency_rates.dart';

// 商品数据模型
class Product {
  final int id;
  String name;
  double price;
  int quantity;
  double unitValue;
  String unit;
  String currency;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitValue,
    required this.unit,
    required this.currency,
  });

  // 复制方法，用于更新商品数据
  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    double? unitValue,
    String? unit,
    String? currency,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unitValue: unitValue ?? this.unitValue,
      unit: unit ?? this.unit,
      currency: currency ?? this.currency,
    );
  }
}

// 计算结果模型
class ComparisonResult {
  final double pricePerBaseUnit;
  final double baseUnitsPerCurrency;
  final double totalBaseUnits;

  ComparisonResult({
    required this.pricePerBaseUnit,
    required this.baseUnitsPerCurrency,
    required this.totalBaseUnits,
  });
}

class PriceComparisonPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PriceComparisonPage({super.key, this.onBack});

  @override
  State<PriceComparisonPage> createState() => _PriceComparisonPageState();
}

class _PriceComparisonPageState extends State<PriceComparisonPage> {


  // 商品列表
  List<Product> _products = [];

  // 基准货币
  String _baseCurrency = 'CNY';

  // 是否显示结果
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // 初始化商品数据（清空状态）
    _products = [
      Product(
        id: 1,
        name: "",
        price: 0.0,
        quantity: 1,
        unitValue: 0.0,
        unit: "g",
        currency: "CNY",
      ),
      Product(
        id: 2,
        name: "",
        price: 0.0,
        quantity: 1,
        unitValue: 0.0,
        unit: "g",
        currency: "CNY",
      ),
    ];
  }



  // 添加新商品
  void _addProduct() {
    final newId = _products.isEmpty ? 1 : _products.last.id + 1;
    final productName = "商品${String.fromCharCode(64 + newId)}";
    setState(() {
      _products.add(Product(
        id: newId,
        name: productName,
        price: 10.0,
        quantity: 1,
        unitValue: 100.0,
        unit: "g",
        currency: "CNY",
      ));
    });
  }

  // 移除商品
  void _removeProduct(int id) {
    if (_products.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("至少需要两种商品进行比较")),
      );
      return;
    }
    setState(() {
      _products.removeWhere((product) => product.id == id);
      _showResults = false;
    });
  }

  // 更新商品数据
  void _updateProduct(Product updatedProduct) {
    setState(() {
      final index = _products.indexWhere((product) => product.id == updatedProduct.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _showResults = false;
    });
  }

  // 重置数据
  void _resetData() {
    setState(() {
      _products = [
        Product(
          id: 1,
          name: "",
          price: 0.0,
          quantity: 1,
          unitValue: 0.0,
          unit: "g",
          currency: "CNY",
        ),
        Product(
          id: 2,
          name: "",
          price: 0.0,
          quantity: 1,
          unitValue: 0.0,
          unit: "g",
          currency: "CNY",
        ),
      ];
      _baseCurrency = 'CNY';
      _showResults = false;
    });
  }

  // 计算比较结果
  void _calculateComparison() {
    // 验证数据
    for (final product in _products) {
      if (product.price <= 0 || product.unitValue <= 0 || product.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("请为${product.name}输入有效的正数值")),
        );
        return;
      }
    }

    setState(() {
      _showResults = true;
    });
  }

  // 计算商品的比较结果
  ComparisonResult _calculateResult(Product product) {
    // 转换为基准货币
    final basePrice = convertToBaseCurrency(product.price, product.currency, _baseCurrency);
    // 转换为基准单位
    final conversionFactor = unitConversion[product.unit] ?? 1.0;
    final totalBaseUnits = product.unitValue * product.quantity * conversionFactor;
    // 计算每基准单位价格
    final pricePerBaseUnit = basePrice / totalBaseUnits;
    // 计算每货币单位可购买的基准单位数
    final baseUnitsPerCurrency = totalBaseUnits / basePrice;

    return ComparisonResult(
      pricePerBaseUnit: pricePerBaseUnit,
      baseUnitsPerCurrency: baseUnitsPerCurrency,
      totalBaseUnits: totalBaseUnits,
    );
  }

  // 创建商品卡片
  Widget _buildProductCard(Product product) {
    final unitCategory = getUnitCategory(product.unit);
    final unitsInCategory = unitCategories[unitCategory] ?? unitCategories['数量']!;
    final currencies = currencyRates.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '商品名称',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  controller: TextEditingController(text: product.name),
                  onChanged: (value) {
                    _updateProduct(product.copyWith(name: value));
                  },
                ),
              ),
              if (_products.length > 2)
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _removeProduct(product.id),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '价格',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: product.price.toString()),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0.0;
                    _updateProduct(product.copyWith(price: price));
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  initialValue: product.currency,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  items: currencies
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateProduct(product.copyWith(currency: value));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '规格数值',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: product.unitValue.toString()),
                  onChanged: (value) {
                    final unitValue = double.tryParse(value) ?? 0.0;
                    _updateProduct(product.copyWith(unitValue: unitValue));
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  initialValue: product.unit,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  items: unitsInCategory
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateProduct(product.copyWith(unit: value));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: InputDecoration(
              labelText: '商品数量（件数）',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: product.quantity.toString()),
            onChanged: (value) {
              final quantity = int.tryParse(value) ?? 1;
              _updateProduct(product.copyWith(quantity: quantity));
            },
          ),
        ],
      ),
    );
  }

  // 构建推荐结果
  Widget _buildRecommendation() {
    if (_products.length < 2) return Container();

    final results = _products.map((p) => _calculateResult(p)).toList();
    final minIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(min));
    final maxIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(max));
    final cheapestProduct = _products[minIndex];
    final mostExpensiveProduct = _products[maxIndex];
    final mostExpensiveResult = results[maxIndex];
    final cheapestResult = results[minIndex]; // 移动位置避免重复定义

    final savingsPercent = ((mostExpensiveResult.pricePerBaseUnit - cheapestResult.pricePerBaseUnit) / mostExpensiveResult.pricePerBaseUnit * 100);
    final baseUnitName = getBaseUnitName(cheapestProduct.unit);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推荐购买：${cheapestProduct.name}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${cheapestProduct.name}的单位价格更划算，比${mostExpensiveProduct.name}便宜${savingsPercent.toStringAsFixed(1)}%。',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '具体数据：${cheapestProduct.name}每$baseUnitName价格为 ${cheapestResult.pricePerBaseUnit.toStringAsFixed(4)} $_baseCurrency，而${mostExpensiveProduct.name}为 ${mostExpensiveResult.pricePerBaseUnit.toStringAsFixed(4)} $_baseCurrency。',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // 构建比较方法卡片
  Widget _buildComparisonMethods() {
    if (_products.length < 2) return Container();

    final results = _products.map((p) => _calculateResult(p)).toList();
    final minIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(min));
    final maxIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(max));
    final cheapestProduct = _products[minIndex];
    final cheapestResult = results[minIndex];
    final mostExpensiveResult = results[maxIndex];

    final baseUnitName = getBaseUnitName(cheapestProduct.unit);
    final priceDiffPerBaseUnit = (mostExpensiveResult.pricePerBaseUnit - cheapestResult.pricePerBaseUnit);
    final extraBaseUnitsPerCurrency = (cheapestResult.baseUnitsPerCurrency - mostExpensiveResult.baseUnitsPerCurrency);

    // 计算购买相同基准单位数时的价格差异
    const sameBaseUnits = 1000.0;
    final priceForCheapest = (cheapestResult.pricePerBaseUnit * sameBaseUnits);
    final priceForExpensive = (mostExpensiveResult.pricePerBaseUnit * sameBaseUnits);
    final priceDiffForSameUnits = (priceForExpensive - priceForCheapest);

    // 计算相同价格可购买的基准单位差异
    const samePrice = 100.0;
    final unitsForCheapest = (cheapestResult.baseUnitsPerCurrency * samePrice);
    final unitsForExpensive = (mostExpensiveResult.baseUnitsPerCurrency * samePrice);
    final unitsDiffForSamePrice = (unitsForCheapest - unitsForExpensive);

    final methods = [
      {
        'title': '方法一：每$baseUnitName价格比较',
        'result': '${cheapestProduct.name}每$baseUnitName便宜 ${priceDiffPerBaseUnit.toStringAsFixed(4)} $_baseCurrency',
        'desc': '计算每$baseUnitName的价格，数值越小越划算',
      },
      {
        'title': '方法二：每$_baseCurrency购买量比较',
        'result': '每$_baseCurrency可多购买 ${extraBaseUnitsPerCurrency.toStringAsFixed(2)} $baseUnitName',
        'desc': '计算每1$_baseCurrency可以购买多少$baseUnitName，数值越大越划算',
      },
      {
        'title': '方法三：购买相同$baseUnitName数',
        'result': '购买${sameBaseUnits.toInt()}$baseUnitName可节省 ${priceDiffForSameUnits.toStringAsFixed(2)} $_baseCurrency',
        'desc': '购买相同数量的$baseUnitName，比较总价格差异',
      },
      {
        'title': '方法四：花费相同金额',
        'result': '花费${samePrice.toInt()}$_baseCurrency可多买 ${unitsDiffForSamePrice.toStringAsFixed(2)} $baseUnitName',
        'desc': '花费相同金额，比较可购买数量的差异',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                method['title']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              Text(
                method['result']!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                method['desc']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建单位价格对比表
  Widget _buildUnitTable() {
    if (_products.length < 2) return Container();

    final results = _products.map((p) => _calculateResult(p)).toList();
    final minIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(min));
    final cheapestProduct = _products[minIndex];
    final baseUnitName = getBaseUnitName(cheapestProduct.unit);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              '商品名称',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '总价（$_baseCurrency）',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '总$baseUnitName数',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '每$baseUnitName价格（$_baseCurrency）',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '每$_baseCurrency可购买$baseUnitName数',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: List.generate(_products.length, (index) {
          final product = _products[index];
          final result = results[index];
          final isCheapest = product.id == cheapestProduct.id;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Text(product.name),
                    if (isCheapest)
                      const Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(Text(convertToBaseCurrency(product.price, product.currency, _baseCurrency).toStringAsFixed(2))),
              DataCell(Text(result.totalBaseUnits.toStringAsFixed(2))),
              DataCell(Text(result.pricePerBaseUnit.toStringAsFixed(4))),
              DataCell(Text(result.baseUnitsPerCurrency.toStringAsFixed(2))),
            ],
            color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (isCheapest) {
                  return Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5);
                }
                return null;
              },
            ),
          );
        }),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currencies = currencyRates.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('价格比较计算器'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 返回计算器选择页面
            widget.onBack?.call();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            Center(
              child: Text(
                '复杂商品价格比较计算器',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '输入不同规格的多种商品信息，获取详细的单位价格比较结果',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // 基准货币选择
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('基准货币：', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _baseCurrency,
                    items: currencies
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(
                                currency,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _baseCurrency = value;
                          if (_showResults) {
                            _calculateComparison();
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // 商品输入区域
            Text(
              '商品信息输入',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // 商品卡片列表
            Column(
              children: _products.map(_buildProductCard).toList(),
            ),

            // 添加商品按钮
            Center(
              child: ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('添加更多商品'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _calculateComparison,
                  icon: const Icon(Icons.calculate),
                  label: const Text('计算比较结果'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _resetData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置所有数据'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 结果区域
            if (_showResults)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '价格比较结果',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 推荐结果
                  _buildRecommendation(),

                  // 详细比较方法
                  Text(
                    '详细比较方法',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildComparisonMethods(),
                  const SizedBox(height: 30),

                  // 单位价格对比表
                  Text(
                    '单位价格对比表',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUnitTable(),
                  const SizedBox(height: 30),

                  // 注意事项
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.amber, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            '注意：此计算结果基于您输入的数据和选择的单位/货币转换。实际购买时还需考虑品牌、质量、个人偏好等因素。',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
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
    );
  }
}
