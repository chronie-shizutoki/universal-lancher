import 'package:flutter/material.dart';
import 'dart:math';
import '../data/unit_conversion.dart';
import '../data/currency_rates.dart';

// 自定义液态玻璃风格通知组件
class GlassSnackBar extends StatelessWidget {
  final String message;
  final Duration duration;

  const GlassSnackBar({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDarkMode ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示通知的静态方法
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GlassSnackBar(message: message),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

 // 定义下拉选项类型
enum DropdownItemType {
  group,
  item,
}

// 下拉选项数据结构
class DropdownItem<T> {
  final DropdownItemType type;
  final T? value;
  final String? groupName;

  DropdownItem.item(this.value) : type = DropdownItemType.item, groupName = null;
  DropdownItem.group(this.groupName) : type = DropdownItemType.group, value = null;
}

// 液态玻璃下拉选择框组件（完全自定义实现）
class GlassDropdown<T> extends StatefulWidget {
  final T value;
  final List<DropdownItem<T>> items;
  final String label;
  final Widget Function(DropdownItem<T>) itemBuilder;
  final void Function(T?) onChanged;
  final double width;

  const GlassDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.itemBuilder,
    required this.onChanged,
    this.width = double.infinity,
  });

  @override
  State<GlassDropdown<T>> createState() => _GlassDropdownState<T>();
}

class _GlassDropdownState<T> extends State<GlassDropdown<T>> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // 用于定位下拉菜单
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationStatusListener _animationStatusListener;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // 监听动画状态，在动画完成时移除Overlay
    _animationStatusListener = (status) {
      if (status == AnimationStatus.dismissed && !_isExpanded) {
        _removeOverlay();
      }
    };
    _animationController.addStatusListener(_animationStatusListener);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_animationStatusListener);
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _showOverlay();
      } else {
        _animationController.reverse();
        // 不在这里立即移除Overlay，等待动画完成后再移除
      }
    });
  }

  void _selectItem(T? value) {
    widget.onChanged(value);
    _toggleExpanded();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: _toggleExpanded,
          child: Stack(
            children: [
              // 背景遮罩
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
              // 下拉菜单
              Positioned(
                left: position.dx,
                top: position.dy + size.height + 8,
                width: size.width,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        origin: const Offset(0, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.15),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.8),
                                      Colors.white.withValues(alpha: 0.6),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 15,
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
                            border: Border.all(
                              color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.items.map((dropdownItem) {
                                  if (dropdownItem.type == DropdownItemType.group) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      child: widget.itemBuilder(dropdownItem),
                                    );
                                  } else {
                                    final isSelected = dropdownItem.value == widget.value;
                                    return GestureDetector(
                                      onTap: () {
                                        _selectItem(dropdownItem.value);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: isDarkMode
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.black.withValues(alpha: 0.05),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: DefaultTextStyle(
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : (isDarkMode ? Colors.white70 : Colors.black87),
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                                child: widget.itemBuilder(dropdownItem),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check,
                                                size: 18,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.width,
      child: GestureDetector(
        key: _buttonKey,
        onTap: _toggleExpanded,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.5),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label.isNotEmpty)
                Text(
                  widget.label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              Expanded(
                child: widget.itemBuilder(
                  DropdownItem<T>.item(widget.value)
                ),
              ),
              RotationTransition(
                turns: Tween<double>(begin: 0, end: _isExpanded ? 0.5 : 0).animate(
                  CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  // 为每个产品字段创建的控制器映射
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    // 初始化商品数据
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
    
    // 初始化控制器
    _initializeControllers();
  }
  
  // 初始化控制器
  void _initializeControllers() {
    _controllers.clear();
    for (var product in _products) {
      _controllers[product.id] = {
        'name': TextEditingController(text: product.name),
        'price': TextEditingController(text: product.price.toString()),
        'unitValue': TextEditingController(text: product.unitValue.toString()),
        'quantity': TextEditingController(text: product.quantity.toString()),
      };
    }
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
      _initializeControllers();
    });
  }

  // 移除商品
  void _removeProduct(int id) {
    if (_products.length <= 2) {
      GlassSnackBar.show(context, "至少需要两种商品进行比较");
      return;
    }
    setState(() {
      _products.removeWhere((product) => product.id == id);
      _showResults = false;
      _initializeControllers();
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
      _initializeControllers();
    });
  }

  // 计算比较结果
  void _calculateComparison() {
    // 验证数据
    for (final product in _products) {
      if (product.price <= 0 || product.unitValue <= 0 || product.quantity <= 0) {
        GlassSnackBar.show(context, "请为${product.name}输入有效的正数值");
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

  // 液态玻璃容器组件
  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 20,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
      padding: padding,
      margin: const EdgeInsets.only(bottom: 20),
      child: child,
    );
  }

  // 液态玻璃按钮组件
  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    Color? buttonColor,
  }) {
    final theme = Theme.of(context);
    final color = buttonColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(25),
            splashColor: Colors.white.withValues(alpha: 0.3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 液态玻璃文本输入框组件
  Widget _buildGlassTextField({
    required int productId,
    required String field,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = _controllers[productId]![field];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        keyboardType: keyboardType,
        onChanged: onChanged,
        controller: controller,
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // 创建商品卡片
  Widget _buildProductCard(Product product) {
    final currencies = currencyRates.keys.toList();
    
    // 构建货币下拉选项（未分组）
    final currencyItems = currencies.map((currency) => DropdownItem<String>.item(currency)).toList();
    
    // 构建单位下拉选项（按类别分组）
    final unitItems = <DropdownItem<String>>[];
    for (final category in unitCategories.keys) {
      unitItems.add(DropdownItem<String>.group(category));
      for (final unit in unitCategories[category]!) {
        unitItems.add(DropdownItem<String>.item(unit));
      }
    }

    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: _buildGlassTextField(
                    productId: product.id,
                    field: 'name',
                    labelText: '商品名称',
                    onChanged: (value) {
                    _updateProduct(product.copyWith(name: value));
                  },
                  ),
              ),
              if (_products.length > 2)
                GestureDetector(
                  onTap: () => _removeProduct(product.id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildGlassTextField(
                  productId: product.id,
                  field: 'price',
                  labelText: '价格',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0.0;
                    _updateProduct(product.copyWith(price: price));
                  },
                ),
              ),
              const SizedBox(width: 12),
              GlassDropdown<String>(
                value: product.currency,
                items: currencyItems,
                label: '',
                itemBuilder: (dropdownItem) {
                  if (dropdownItem.type == DropdownItemType.group) {
                    return Container();
                  } else {
                    return Text(
                      currencyNames[dropdownItem.value!] ?? dropdownItem.value!,
                      style: const TextStyle(fontSize: 14),
                    );
                  }
                },
                onChanged: (value) {
                  if (value != null) {
                    _updateProduct(product.copyWith(currency: value));
                  }
                },
                width: 120,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildGlassTextField(
                  productId: product.id,
                  field: 'unitValue',
                  labelText: '规格数值',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final unitValue = double.tryParse(value) ?? 0.0;
                    _updateProduct(product.copyWith(unitValue: unitValue));
                  },
                ),
              ),
              const SizedBox(width: 12),
              GlassDropdown<String>(
                value: product.unit,
                items: unitItems,
                label: '',
                itemBuilder: (dropdownItem) {
                  if (dropdownItem.type == DropdownItemType.group) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        dropdownItem.groupName!, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  } else {
                    return Text(
                      dropdownItem.value!,
                      style: const TextStyle(fontSize: 14),
                    );
                  }
                },
                onChanged: (value) {
                  if (value != null) {
                    _updateProduct(product.copyWith(unit: value));
                  }
                },
                width: 120,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildGlassTextField(
            productId: product.id,
            field: 'quantity',
            labelText: '商品数量（件数）',
            keyboardType: TextInputType.number,
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
    final cheapestResult = results[minIndex];

    final savingsPercent = ((mostExpensiveResult.pricePerBaseUnit - cheapestResult.pricePerBaseUnit) / mostExpensiveResult.pricePerBaseUnit * 100);
    final baseUnitName = getBaseUnitName(cheapestProduct.unit);

    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推荐购买：${cheapestProduct.name}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${cheapestProduct.name}的单位价格更划算，比${mostExpensiveProduct.name}便宜${savingsPercent.toStringAsFixed(1)}%。',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '具体数据：${cheapestProduct.name}每$baseUnitName价格为 ${cheapestResult.pricePerBaseUnit.toStringAsFixed(4)} $_baseCurrency，而${mostExpensiveProduct.name}为 ${mostExpensiveResult.pricePerBaseUnit.toStringAsFixed(4)} $_baseCurrency。',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
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

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: methods.map((method) {
        return SizedBox(
          width: 300, // 设置卡片的宽度
          child: _buildGlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        );
      }).toList(),
    );
  }

  // 构建单位价格对比表
  Widget _buildUnitTable() {
    if (_products.length < 2) return Container();

    final results = _products.map((p) => _calculateResult(p)).toList();
    final minIndex = results.indexWhere((r) => r.pricePerBaseUnit == results.map((r) => r.pricePerBaseUnit).reduce(min));
    final cheapestProduct = _products[minIndex];
    final baseUnitName = getBaseUnitName(cheapestProduct.unit);

    return _buildGlassContainer(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '商品名称',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '总价（$_baseCurrency）',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '总$baseUnitName数',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '每$baseUnitName价格（$_baseCurrency）',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '每$_baseCurrency可购买$baseUnitName数',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(convertToBaseCurrency(product.price, product.currency, _baseCurrency).toStringAsFixed(2)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(result.totalBaseUnits.toStringAsFixed(2)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(result.pricePerBaseUnit.toStringAsFixed(4)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(result.baseUnitsPerCurrency.toStringAsFixed(2)),
                  ),
                ),
              ],
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (isCheapest) {
                    return Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3);
                  }
                  return null;
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencies = currencyRates.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('价格比较计算器'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 返回计算器选择页面
            if (widget.onBack != null) {
              widget.onBack?.call();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          width: isLargeScreen ? screenWidth * 0.8 : screenWidth,
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
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
                _buildGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('基准货币：', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassDropdown<String>(
                        value: _baseCurrency,
                        items: currencies.map((currency) => DropdownItem<String>.item(currency)).toList(),
                        label: '',
                        itemBuilder: (dropdownItem) {
                          if (dropdownItem.type == DropdownItemType.group) {
                            return Container();
                          } else {
                            return Text(
                              currencyNames[dropdownItem.value!] ?? dropdownItem.value!,
                              style: const TextStyle(fontSize: 18),
                            );
                          }
                        },
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

                // 所有操作按钮
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                    _buildGlassButton(
                      onPressed: _addProduct,
                      text: '添加更多商品',
                      icon: Icons.add,
                      buttonColor: Theme.of(context).colorScheme.secondary,
                    ),
                    _buildGlassButton(
                      onPressed: _calculateComparison,
                      text: '计算比较结果',
                      icon: Icons.calculate,
                    ),
                    _buildGlassButton(
                      onPressed: _resetData,
                      text: '重置所有数据',
                      icon: Icons.refresh,
                      buttonColor: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
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
                      _buildGlassContainer(
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.amber, size: 30),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                '注意：此计算结果基于您输入的数据和选择的单位/货币转换。实际购买时还需考虑品牌、质量、个人偏好等因素。',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
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
        ),
      ),
    );
  }
}
