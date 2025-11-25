import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import '../models/food_category.dart';

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
  List<Color> _wheelColors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
  int _selectedIndex = 0;

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
    
    // 随机选择一个最终角度，使转盘看起来更自然且更震撼
    final random = Random();
    // 增加旋转圈数，使其更震撼（4-6圈）
    final rotationMultiplier = 4 + random.nextInt(3); // 4-6圈
    final targetRotation = rotationMultiplier * 360.0 + (random.nextDouble() * 360.0);
    
    // 重置动画并重新开始
    _controller.reset();
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: targetRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        // 使用更自然的曲线：先快后慢，有一个加速再减速的过程
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
      // 旋转结束后选择食物
      _selectFood();
    });
    
    _controller.forward().then((_) {
      // 旋转结束后选择食物
      _selectFood();
    });
  }

  void _selectFood() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    final food = provider.getRandomFood();
    setState(() {
      _selectedFood = food;
      _isSpinning = false;
    });
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
            // Tab切换 - 添加顶部内边距
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton('随机选择', 0),
                  _buildTabButton('周计划', 1),
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
      // 右上角悬浮设置按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _showFoodManagementDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        mini: true,
        shape: const CircleBorder(),
        child: const Icon(Icons.settings),
        elevation: 4.0,
        tooltip: '食物管理',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
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
        backgroundColor: _currentTab == index ? Colors.blue : Colors.grey[200],
        foregroundColor: _currentTab == index ? Colors.white : Colors.black,
      ),
      child: Text(title),
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
                  
                  // 旋转的转盘
                  Transform.rotate(
                    angle: _rotation * pi / 180,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.orange.shade400, Colors.red.shade600],
                          radius: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isSpinning
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            )
                          : _selectedFood != null
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _selectedFood!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )
                              )
                                : Center(
                                    child: Text(
                                      '点击开始',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          const Shadow(
                                            color: Colors.black,
                                            blurRadius: 3,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                    ),
                  ),
                  // 指示器
                  Positioned(
                    top: 20,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      )
                    ),
                  ),
                ],
              ),
              
              // 结果展示（选中后显示）
              if (!_isSpinning && _selectedFood != null)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade400, width: 2),
                  ),
                  child: Text(
                    '今天就吃${_selectedFood!.name}吧！',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                )
            ],
          ),
        ),

        // 操作按钮区域
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _spinWheel,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: _isSpinning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('今天吃什么？'),
              ),
              
              const SizedBox(height: 14),
              
              // 重新选择按钮
              if (!_isSpinning && _selectedFood != null)
                ElevatedButton(
                  onPressed: _spinWheel,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('换一个'),
                ),
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

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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