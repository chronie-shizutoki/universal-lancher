import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';

// 预定义渐变色列表
final List<LinearGradient> _wheelGradients = [
  LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
  LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
  LinearGradient(colors: [Colors.yellow.shade400, Colors.yellow.shade600]),
  LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
  LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
  LinearGradient(colors: [Colors.purple.shade400, Colors.purple.shade600]),
  LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600]),
  LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600]),
];

// 自定义画笔，用于绘制转盘扇形分区
class _WheelPainter extends CustomPainter {
  final List<FoodItem> foodItems;
  
  _WheelPainter(this.foodItems);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (foodItems.isEmpty) {
      // 如果没有食物，绘制一个简单的圆
      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 2;
      
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius, paint);
      
      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, borderPaint);
      
      // 绘制提示文字
      final textSpan = const TextSpan(
        text: '暂无食物',
        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
      
      return;
    }
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 计算总权重
    final totalWeight = foodItems.map((item) => item.weight).reduce((a, b) => a + b);
    
    // 计算每个食物对应的角度范围
    double currentAngle = -pi / 2; // 从顶部开始（-90度）
    
    for (int i = 0; i < foodItems.length; i++) {
      final food = foodItems[i];
      final foodAngle = 2 * pi * (food.weight / totalWeight);
      final startAngle = currentAngle;
      final endAngle = currentAngle + foodAngle;
      
      // 获取或循环使用渐变色
      final gradientIndex = i % _wheelGradients.length;
      
      // 使用渐变色填充扇形
      final paint = Paint()
        ..shader = _wheelGradients[gradientIndex]
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          foodAngle,
          false,
        )
        ..close();
      
      canvas.drawPath(path, paint);
      
      // 绘制精致的分区线
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        linePaint,
      );
      
      // 绘制食物名称
      _drawFoodName(canvas, center, radius, startAngle, foodAngle, food.name, size.width);
      
      currentAngle = endAngle;
    }
    
    // 绘制精致黑色边框
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, borderPaint);
    
    // 添加金色边框装饰
    final accentPaint = Paint()
      ..color = Colors.amber.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2.0, accentPaint);
  }
  
  // 绘制食物名称
  void _drawFoodName(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String name, double wheelSize) {
    // 计算文字位置（在扇形中间）
    final textAngle = startAngle + sweepAngle / 2;
    final textRadius = radius * 0.7; // 文字位置半径，小于转盘半径
    
    final textOffset = Offset(
      center.dx + textRadius * cos(textAngle),
      center.dy + textRadius * sin(textAngle),
    );
    
    // 根据转盘大小调整字体大小
    double fontSize = wheelSize < 150 ? 10.0 : (wheelSize < 200 ? 12.0 : 14.0);
    
    // 如果扇形角度太小，可能不适合显示文字
    if (sweepAngle < pi / 8) { // 小于22.5度
      return;
    }
    
    // 创建文字样式
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(
          blurRadius: 3.0,
          color: Colors.black,
          offset: Offset(1.0, 1.0),
        ),
      ],
    );
    
    // 创建TextSpan
    final textSpan = TextSpan(
      text: name,
      style: textStyle,
    );
    
    // 创建TextPainter
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // 计算文字大小
    textPainter.layout(minWidth: 0, maxWidth: radius * 1.5);
    
    // 保存当前画布状态
    canvas.save();
    
    // 将画布原点移动到文字位置
    canvas.translate(textOffset.dx, textOffset.dy);
    
    // 旋转画布，使文字朝向圆心
    canvas.rotate(textAngle + pi / 2);
    
    // 绘制文字，居中显示
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    
    // 恢复画布状态
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  double _rotation = 0.0;
  bool _isSpinning = false;
  FoodItem? _selectedFood;
  bool _showWeeklyPlan = false;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // 创建旋转动画
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 720.0, // 旋转2圈
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );
    
    _rotationAnimation.addListener(() {
      setState(() {
        _rotation = _rotationAnimation.value;
      });
    });

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    _isSpinning = true;
    _selectedFood = null;
    
    // 先随机选择一个食物
    final provider = Provider.of<FoodProvider>(context, listen: false);
    final selectedFood = provider.getRandomFood();
    _selectedFood = selectedFood; // 保存选择的食物
    
    // 计算这个食物在转盘中的角度位置
    // 确保selectedFood不为null
    final targetAngle = _calculateTargetAngle(selectedFood!, provider.foodItems);
    
    // 随机选择旋转圈数（4-6圈）
    final random = Random();
    final rotationMultiplier = 4 + random.nextInt(3); // 4-6圈
    final targetRotation = rotationMultiplier * 360.0 + targetAngle;
    
    // 重置动画并重新开始
    _controller.reset();
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: targetRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // 使用弹性曲线增加震撼感
      ),
    );
    
    // 在动画开始时添加震动反馈
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // 可选：添加震动反馈（需要导入vibration包）
      }
    });
    
    _controller.forward().then((_) {
      // 旋转结束后更新状态
      setState(() {
        _isSpinning = false;
      });
    });
  }

  double _calculateTargetAngle(FoodItem selectedFood, List<FoodItem> foodItems) {
    // 计算每个食物对应的角度范围
    final totalWeight = foodItems.map((item) => item.weight).reduce((a, b) => a + b);
    
    // 与WheelPainter保持一致，从顶部开始计算角度（-90度）
    // 使用角度单位
    double currentAngle = -90.0;
    
    // 找到选中食物的扇形区域
    for (final food in foodItems) {
      final foodAngle = 360.0 * (food.weight / totalWeight);
      
      // 计算当前食物的角度范围
      final startAngle = currentAngle;
      final endAngle = currentAngle + foodAngle;
      
      // 检查是否是选中的食物
      if (food.id == selectedFood.id) {
        // 计算食物扇形中间的角度 - 这是指针应该指向的位置
        final foodMiddleAngle = startAngle + foodAngle / 2;
        
        // 关键修复：确保旋转方向和角度计算正确
        // 为了让指针精确指向食物中间，我们需要：
        // 1. 计算食物中间与顶部的夹角差
        // 2. 考虑旋转方向，确保最终指向正确
        double targetAngle;
        
        if (foodMiddleAngle < 0) {
          // 如果食物中间角度小于0度，需要特别处理
          targetAngle = (-foodMiddleAngle + 360.0) % 360.0;
        } else {
          targetAngle = (360.0 - foodMiddleAngle) % 360.0;
        }
        
        // 确保返回值在0-360度范围内
        return targetAngle;
      }
      
      // 移动到下一个食物的起始角度
      currentAngle = endAngle;
    }
    
    // 如果没找到食物，默认返回0度
    return 0.0;
  }

  void _generateWeeklyPlan() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    provider.generateWeeklyPlan();
    setState(() {
      _showWeeklyPlan = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.purple.shade900,
                    Colors.blue.shade900,
                    Colors.green.shade900,
                  ]
                : [
                    Colors.purple.shade100,
                    Colors.blue.shade100,
                    Colors.green.shade100,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Consumer<FoodProvider>(builder: (context, provider, child) {
          return Column(
            children: [
              // 顶部按钮区域 - 三个按钮在同一行
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 左侧的随机选择和周计划按钮
                    Row(
                      children: [
                        _buildGlassTabButton('随机选择', 0),
                        const SizedBox(width: 8),
                        _buildGlassTabButton('周计划', 1),
                      ],
                    ),
                    // 右侧的设置按钮
                    _buildGlassSettingButton(),
                  ],
                ),
              ),

              Expanded(
                child: _currentTab == 0 ? _buildRandomSelection(provider) : _buildWeeklyPlan(provider),
              ),
            ],
          );
        }),
      ),
      // 添加底部安全占位区域
      bottomNavigationBar: const SizedBox(height: 60),
    );
  }

  // 构建玻璃风格的标签按钮
  Widget _buildGlassTabButton(String title, int index) {
    final isSelected = _currentTab == index;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTab = index;
            });
          },
          borderRadius: BorderRadius.circular(25),
          splashColor: isSelected ? Colors.white.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建玻璃风格的设置按钮
  Widget _buildGlassSettingButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFoodManagementDialog,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.blue.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.settings, size: 24, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildRandomSelection(FoodProvider provider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // 转盘和结果展示
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 转盘
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景装饰 - 玻璃效果
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ]
                            : [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                  ),
                  
                  // 旋转的转盘 - 包含扇形分区
                  Transform.rotate(
                    angle: _rotation * pi / 180, // 将角度转换为弧度
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _WheelPainter(provider.foodItems),
                      ),
                    ),
                  ),
                  
                  // 固定在中心的指示器
                  Positioned(
                    top: 0,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 中心装饰
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.red.shade500,
                                  Colors.red.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          // 指针
                          Positioned(
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.red.shade500,
                                    Colors.red.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // 显示选中的食物
              if (!_isSpinning && _selectedFood != null)
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: _buildGlassResultCard(_selectedFood!),
                ),
            ],
          ),
        ),

        // 操作按钮区域
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 根据状态显示不同的按钮
              (!_isSpinning && _selectedFood != null) 
                ? _buildGlassButton('换一个', Colors.orange, _spinWheel)
                : (!_isSpinning && _selectedFood == null)
                    ? _buildGlassButton('今天吃什么？', Colors.red, _spinWheel)
                    : _buildGlassButton('旋转中...', Colors.red.shade700, null, isLoading: true)
            ],
          ),
        ),
      ],
    );
  }

  // 构建玻璃风格的结果卡片
  Widget _buildGlassResultCard(FoodItem food) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.6),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '推荐',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            food.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (food.category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                food.category,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建玻璃风格的按钮
  Widget _buildGlassButton(String text, Color primaryColor, VoidCallback? onPressed, {bool isLoading = false, double fontSize = 16}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.9),
            primaryColor.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            width: double.infinity,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPlan(FoodProvider provider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      children: [
        // 计划信息和操作按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 上次生成计划时间
              if (provider.lastPlanDate != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '上次生成时间：${_formatDate(provider.lastPlanDate!)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),

              // 生成和重置按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildGlassButton('生成周计划', Colors.green, _generateWeeklyPlan),
                  ),
                  const SizedBox(width: 12),
                  if (provider.weeklyPlan.isNotEmpty)
                    Container(
                      width: 100,
                      child: _buildGlassButton('重置', Colors.red, () {
                        final provider = Provider.of<FoodProvider>(context, listen: false);
                        provider.resetWeeklyPlan();
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 周计划网格
        Expanded(
          child: provider.weeklyPlan.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: provider.weeklyPlan.length,
                  itemBuilder: (context, index) {
                    final food = provider.weeklyPlan[index];
                    final gradientColors = [
                      Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1),
                      Colors.yellow.withOpacity(0.2), Colors.yellow.withOpacity(0.1),
                      Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1),
                      Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1),
                      Colors.indigo.withOpacity(0.2), Colors.indigo.withOpacity(0.1),
                      Colors.purple.withOpacity(0.2), Colors.purple.withOpacity(0.1),
                    ];
                    
                    return AnimatedContainer(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            gradientColors[index * 2],
                            gradientColors[index * 2 + 1],
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      duration: const Duration(milliseconds: 500),
                      transform: Matrix4.identity()..scale(1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            food.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (food.category.isNotEmpty)
                            Text(
                              food.category,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有周计划',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方按钮生成一周的饮食计划',
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // 格式化日期时间（包含时分秒）
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  void _showFoodManagementDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 玻璃风格的食物管理对话框
    showDialog(
      context: context, 
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '食物管理',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildGlassDialogButton('添加食物', Icons.add, () {
                  Navigator.pop(context);
                  _showAddFoodDialog();
                }),
                const SizedBox(height: 12),
                _buildGlassDialogButton('查看所有食物', Icons.list, () {
                  Navigator.pop(context);
                  _showFoodListDialog();
                }),
                const SizedBox(height: 24),
                _buildGlassButton('关闭', Colors.grey, () {
                  Navigator.pop(context);
                }, fontSize: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建玻璃风格的对话框按钮
  Widget _buildGlassDialogButton(String text, IconData icon, VoidCallback onPressed) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.6),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.blue.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFoodDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController weightController = TextEditingController(text: '1.0');
    
    showDialog(
      context: context, 
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '添加菜品',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassTextField(nameController, '菜品名称'),
                  const SizedBox(height: 16),
                  _buildGlassTextField(weightController, '权重', 
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    helperText: '数字越大，被选中的概率越高',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildGlassButton('取消', Colors.grey, () {
                          Navigator.pop(context);
                        }, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassButton('添加', Colors.blue, () {
                          final String name = nameController.text.trim();
                          final String weightText = weightController.text.trim();
                          
                          if (name.isNotEmpty) {
                            double weight = 1.0;
                            if (weightText.isNotEmpty) {
                              try {
                                weight = double.parse(weightText);
                                if (weight <= 0) weight = 1.0;
                              } catch (e) {
                                // 解析失败，使用默认值
                              }
                            }
                            
                            final provider = Provider.of<FoodProvider>(context, listen: false);
                            final int newId = provider.foodItems.isNotEmpty 
                                ? provider.foodItems.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1
                                : 1;
                            
                            provider.addFoodItem(FoodItem(
                              id: newId,
                              name: name,
                              category: '', // 不再需要分类
                              weight: weight,
                            ));
                            
                            Navigator.pop(context);
                          }
                        }, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建玻璃风格的文本输入框
  Widget _buildGlassTextField(TextEditingController controller, String labelText, {
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
          helperText: helperText,
          helperStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _showFoodListDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<FoodProvider>(context, listen: false);
    
    showDialog(
      context: context, 
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '所有食物',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: provider.foodItems.length,
                    itemBuilder: (context, index) {
                      final food = provider.foodItems[index];
                      return _buildFoodListItem(food);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildGlassButton('关闭', Colors.grey, () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建食物列表项
  Widget _buildFoodListItem(FoodItem food) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(food.name, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        trailing: Text('权重: ${food.weight}', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
        tileColor: Colors.transparent,
      ),
    );
  }
}