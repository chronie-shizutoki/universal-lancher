/// 食物分类模型类
class FoodCategory {
  final String id;
  final String name;
  final String color;

  FoodCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  // 从JSON创建FoodCategory实例
  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}