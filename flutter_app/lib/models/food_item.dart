/// 食物模型类
class FoodItem {
  final int id;
  final String name;
  final String category;
  final double weight;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.weight,
  });

  // 从JSON创建FoodItem实例
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      weight: (json['weight'] as num).toDouble(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'weight': weight,
    };
  }

  // 复制方法，用于编辑食物时创建新实例
  FoodItem copyWith({
    int? id,
    String? name,
    String? category,
    double? weight,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      weight: weight ?? this.weight,
    );
  }
}