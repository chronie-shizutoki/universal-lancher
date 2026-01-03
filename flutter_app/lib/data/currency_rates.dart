// 货币汇率数据

// 货币汇率（以USD为基准，更新于2026/1/3）
final Map<String, double> currencyRates = {
  'USD': 1.0,
  'CNY': 6.9937,
  'EUR': 0.8533,
  'GBP': 0.7429,
  'JPY': 156.84,
  'KRW': 1442.48,
  'HKD': 7.7912,
  'SGD': 1.2863,
  'AUD': 1.494,
  'CAD': 1.3729,
};

// 货币名称映射
final Map<String, String> currencyNames = {
  'USD': '美元',
  'CNY': '人民币',
  'EUR': '欧元',
  'GBP': '英镑',
  'JPY': '日元',
  'KRW': '韩元',
  'HKD': '港币',
  'SGD': '新加坡元',
  'AUD': '澳元',
  'CAD': '加元',
};

// 将价格转换为基准货币
double convertToBaseCurrency(double price, String currency, String baseCurrency) {
  if (currency == baseCurrency) return price;
  final rate = currencyRates[currency] ?? 1.0;
  final baseRate = currencyRates[baseCurrency] ?? 1.0;
  return price * (baseRate / rate);
}