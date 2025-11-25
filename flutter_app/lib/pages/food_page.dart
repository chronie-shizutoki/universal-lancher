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
    return Scaffold(
      body: Consumer<FoodProvider>(builder: (context, provider, child) {
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
                      _buildTabButton('随机选择', 0),
                      const SizedBox(width: 8),
                      _buildTabButton('周计划', 1),
                    ],
                  ),
                  // 右侧的设置按钮
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _showFoodManagementDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      child: const Icon(Icons.settings, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _currentTab == 0 ? _buildRandomSelection(provider) : _buildWeeklyPlan(provider),
            ),
          ],
        );
      }),
      // 添加底部安全占位区域
      bottomNavigationBar: const SizedBox(height: 60),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentTab = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentTab == index ? Colors.blue : Colors.grey[100],
        foregroundColor: _currentTab == index ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: _currentTab == index ? 4 : 2,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRandomSelection(FoodProvider provider) {
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
                  // 背景装饰
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  
                  // 旋转的转盘 - 包含扇形分区
                  Transform.rotate(
                    angle: _rotation * pi / 180, // 将角度转换为弧度
                    child: Container(
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
                    child: Container(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 中心装饰
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
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
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                ? ElevatedButton(
                    onPressed: _spinWheel,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text('换一个', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),),
                  )
                : (!_isSpinning && _selectedFood == null)
                    ? ElevatedButton(
                        onPressed: _spinWheel,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text('今天吃什么？'),
                      )
                    : ElevatedButton(
                        onPressed: null, // 旋转时禁用按钮
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyPlan(FoodProvider provider) {
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dayColors = [
      Colors.red.shade100, Colors.orange.shade100, Colors.yellow.shade100,
      Colors.green.shade100, Colors.blue.shade100, Colors.indigo.shade100, Colors.purple.shade100
    ];
    final dayBorderColors = [
      Colors.red.shade400, Colors.orange.shade400, Colors.yellow.shade400,
      Colors.green.shade400, Colors.blue.shade400, Colors.indigo.shade400, Colors.purple.shade400
    ];

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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
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
                    child: ElevatedButton(
                      onPressed: _generateWeeklyPlan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: const Text('生成周计划'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (provider.weeklyPlan.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        final provider = Provider.of<FoodProvider>(context, listen: false);
                        provider.resetWeeklyPlan();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('重置'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 周计划网格
        Expanded(
          child: provider.weeklyPlan.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '还没有周计划',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击上方按钮生成一周的饮食计划',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                )
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
                    
                    return AnimatedContainer(
                      decoration: BoxDecoration(
                        color: dayColors[index],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dayBorderColors[index], width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: dayBorderColors[index],
                            ),
                          ),
                          Text(
                            food.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${food.category}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
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

  // 格式化日期时间（包含时分秒）
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  void _showFoodManagementDialog() {
    // 简化版的食物管理对话框
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('食物管理'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('添加食物'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('查看所有食物'),
                onTap: () {
                  Navigator.pop(context);
                  _showFoodListDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFoodDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController weightController = TextEditingController(text: '1.0');
    
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('添加菜品'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '菜品名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: '权重',
                    border: OutlineInputBorder(),
                    helperText: '数字越大，被选中的概率越高',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
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
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _showFoodListDialog() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('所有食物'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: provider.foodItems.length,
              itemBuilder: (context, index) {
                final food = provider.foodItems[index];
                  return ListTile(
                  title: Text(food.name),
                  trailing: Text('权重: ${food.weight}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}