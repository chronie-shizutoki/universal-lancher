// 单位转换数据

// 单位转换因子（转换为基准单位）
final Map<String, double> unitConversion = {
  // 体积单位转换到毫升(ml)
  'ml': 1,
  'L': 1000,
  'cm³': 1,
  'm³': 1000000,
  'fl oz': 29.5735,
  'cup': 236.588,
  'pint': 473.176,
  'quart': 946.353,
  'gallon': 3785.41,
  'tsp': 4.92892,
  'tbsp': 14.7868,
  'in³': 16.3871,
  'ft³': 28316.8,
  // 重量单位转换到克(g)
  'g': 1,
  'kg': 1000,
  'mg': 0.001,
  'μg': 0.000001,
  'lb': 453.592,
  'oz': 28.3495,
  'ton': 1000000,
  'tonne': 1000000,
  'stone': 6350.29,
  'dr': 1.77185,
  'grain': 0.0647989,
  // 数量单位（没有转换，直接使用）
  '个': 1,
  '件': 1,
  '瓶': 1,
  '包': 1,
  '盒': 1,
  '袋': 1,
  '箱': 1,
  '组': 1,
  '套': 1,
  '支': 1,
  '条': 1,
  '罐': 1,
  '桶': 1,
  '筐': 1,
  '批': 1,
  '份': 1,
  // 长度单位转换到米(m)
  'mm': 0.001,
  'cm': 0.01,
  'm': 1,
  'km': 1000,
  'in': 0.0254,
  'ft': 0.3048,
  'yd': 0.9144,
  'mi': 1609.34,
};

// 单位类别
final Map<String, List<String>> unitCategories = {
  '体积': ['ml', 'L', 'cm³', 'm³', 'fl oz', 'cup', 'pint', 'quart', 'gallon', 'tsp', 'tbsp', 'in³', 'ft³'],
  '重量': ['g', 'kg', 'mg', 'μg', 'lb', 'oz', 'ton', 'tonne', 'stone', 'dr', 'grain'],
  '数量': ['个', '件', '瓶', '包', '盒', '袋', '箱', '组', '套', '支', '条', '罐', '桶', '筐', '批', '份'],
  '长度': ['mm', 'cm', 'm', 'km', 'in', 'ft', 'yd', 'mi'],
};

// 获取单位类别
String getUnitCategory(String unit) {
  for (final category in unitCategories.keys) {
    if (unitCategories[category]!.contains(unit)) {
      return category;
    }
  }
  return '数量';
}

// 获取基准单位名称
String getBaseUnitName(String unit) {
  if (unitCategories['体积']!.contains(unit)) {
    return '毫升(ml)';
  } else if (unitCategories['重量']!.contains(unit)) {
    return '克(g)';
  } else if (unitCategories['长度']!.contains(unit)) {
    return '米(m)';
  } else {
    return '单位';
  }
}