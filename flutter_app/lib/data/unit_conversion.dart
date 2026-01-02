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
  // 重量单位转换到克(g)
  'g': 1,
  'kg': 1000,
  'mg': 0.001,
  'lb': 453.592,
  'oz': 28.3495,
  'ton': 1000000,
  'stone': 6350.29,
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
};

// 单位类别
final Map<String, List<String>> unitCategories = {
  '体积': ['ml', 'L', 'cm³', 'm³', 'fl oz', 'cup', 'pint', 'quart', 'gallon'],
  '重量': ['g', 'kg', 'mg', 'lb', 'oz', 'ton', 'stone'],
  '数量': ['个', '件', '瓶', '包', '盒', '袋', '箱', '组', '套'],
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
  } else {
    return '单位';
  }
}