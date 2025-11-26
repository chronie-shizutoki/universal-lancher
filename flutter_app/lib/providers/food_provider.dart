import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';

class FoodProvider extends ChangeNotifier {
  List<FoodItem> _foodItems = [];
  List<FoodItem> _weeklyPlan = [];
  DateTime? _lastPlanDate;

  List<FoodItem> get foodItems => _foodItems;
  List<FoodItem> get weeklyPlan => _weeklyPlan;
  DateTime? get lastPlanDate => _lastPlanDate;

  // 初始化数据
  Future<void> initialize() async {
    try {
      await _loadData();
    } catch (e) {
      _loadDefaultData();
    }
  }

  // 加载默认数据
  void _loadDefaultData() {
    // 默认食物（使用空字符串作为category，因为我们不再需要分类）
    _foodItems = [
      FoodItem(id: 1, name: '观前街炒饭', category: '', weight: 1.7),
      FoodItem(id: 2, name: '鑫花溪', category: '', weight: 1.0),
      FoodItem(id: 3, name: '小贩的土豆粉', category: '', weight: 1.8),
      FoodItem(id: 4, name: '炒饭', category: '', weight: 1.8),
    ];

    _saveData();
  }

  // 从本地存储加载数据
  Future<void> _loadData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/food_data.json');

      if (file.existsSync()) {
        final contents = await file.readAsString();
        final data = json.decode(contents);

        _foodItems = List<FoodItem>.from(
          data['foods'].map((item) => FoodItem.fromJson(item)),
        );

        // 不再加载分类数据

        if (data.containsKey('weeklyPlan')) {
          _weeklyPlan = List<FoodItem>.from(
            data['weeklyPlan'].map((item) => FoodItem.fromJson(item)),
          );
        }

        if (data.containsKey('lastPlanDate')) {
          _lastPlanDate = DateTime.parse(data['lastPlanDate']);
        }
      } else {
        _loadDefaultData();
      }
    } catch (e) {
      _loadDefaultData();
    }

    notifyListeners();
  }

  // 保存数据到本地存储
  Future<void> _saveData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/food_data.json');

      final data = {
        'foods': _foodItems.map((item) => item.toJson()).toList(),
        'weeklyPlan': _weeklyPlan.map((item) => item.toJson()).toList(),
        'lastPlanDate': _lastPlanDate?.toIso8601String(),
      };

      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('保存数据失败: $e');
    }
  }

  // 添加食物
  Future<void> addFoodItem(FoodItem food) async {
    _foodItems.add(food);
    await _saveData();
    notifyListeners();
  }

  // 更新食物
  Future<void> updateFoodItem(FoodItem food) async {
    final index = _foodItems.indexWhere((item) => item.id == food.id);
    if (index != -1) {
      _foodItems[index] = food;
      await _saveData();
      notifyListeners();
    }
  }

  // 删除食物
  Future<void> deleteFoodItem(int id) async {
    _foodItems.removeWhere((item) => item.id == id);
    await _saveData();
    notifyListeners();
  }

  // 生成随机食物
  FoodItem? getRandomFood() {
    if (_foodItems.isEmpty) return null;

    // 使用Random类生成更可靠的随机数
    final random = Random();
    
    // 基于权重随机选择
    final totalWeight = _foodItems.map((item) => item.weight).reduce((a, b) => a + b);
    double randomValue = random.nextDouble() * totalWeight;
    double currentWeight = 0;

    for (var food in _foodItems) {
      currentWeight += food.weight;
      if (randomValue <= currentWeight) {
        return food;
      }
    }

    // 保险起见，返回第一个元素
    return _foodItems.first;
  }

  // 生成周计划
  Future<void> generateWeeklyPlan() async {
    // 使用新的getRandomFoodList方法生成7天的食物计划
    _weeklyPlan = getRandomFoodList(7);
    _lastPlanDate = DateTime.now();
    await _saveData();
    notifyListeners();
  }

  // 生成随机食物列表（用于周计划）
  List<FoodItem> getRandomFoodList(int count) {
    if (_foodItems.isEmpty) return [];
    
    final random = Random();
    final result = <FoodItem>[];
    
    // 如果食物数量少于请求数量，先添加所有食物，然后再随机添加
    if (_foodItems.length <= count) {
      result.addAll(_foodItems);
      // 随机添加剩余数量
      for (int i = _foodItems.length; i < count; i++) {
        result.add(_foodItems[random.nextInt(_foodItems.length)]);
      }
    } else {
      // 否则，随机选择count个不重复的食物
      final selectedIndices = <int>{};
      while (selectedIndices.length < count) {
        final index = random.nextInt(_foodItems.length);
        selectedIndices.add(index);
      }
      
      for (final index in selectedIndices) {
        result.add(_foodItems[index]);
      }
    }
    
    return result;
  }

  // 重置周计划
  Future<void> resetWeeklyPlan() async {
    _weeklyPlan = [];
    _lastPlanDate = null;
    await _saveData();
    notifyListeners();
  }
}