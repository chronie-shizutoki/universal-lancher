import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:universal_launcher/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lunar/lunar.dart';

const Color _lightTextPrimary = Color(0xFF333333);
const Color _lightTextSecondary = Color(0xFF555555);
const Color _darkTextPrimary = Color(0xFFe2e8f0);
const Color _darkTextSecondary = Color(0xFFa0aec0);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = false;
  String? _weatherError;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isInitialized = true;
    _fetchWeather();
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Location service check timeout');
        },
      );
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Permission check timeout');
        },
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Permission request timeout');
          },
        );
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Get position timeout');
        },
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      final position = await _getCurrentPosition();
      final latitude = position?.latitude ?? 39.9042;
      final longitude = position?.longitude ?? 116.4074;

      final response = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,apparent_temperature,pressure_msl,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,wind_speed_10m_max&timezone=auto'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Weather request timeout');
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoadingWeather = false;
        });
      } else {
        setState(() {
          _weatherError = 'Failed to load weather (Status: ${response.statusCode})';
          _isLoadingWeather = false;
        });
      }
    } on TimeoutException catch (e) {
      setState(() {
        _weatherError = 'Request timeout: ${e.message ?? 'Please check your connection'}';
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = 'Error: ${e.toString()}';
        _isLoadingWeather = false;
      });
    }
  }

  String _getWeatherDescription(dynamic code) {
    final Map<int, String> weatherCodes = {
      0: '晴朗',
      1: '多云',
      2: '多云',
      3: '阴天',
      45: '雾',
      48: '雾凇',
      51: '毛毛雨',
      53: '毛毛雨',
      55: '毛毛雨',
      61: '小雨',
      63: '中雨',
      65: '大雨',
      71: '小雪',
      73: '中雪',
      75: '大雪',
      80: '阵雨',
      81: '阵雨',
      82: '暴雨',
      95: '雷雨',
      96: '雷雨伴有冰雹',
      99: '雷雨伴有冰雹',
    };
    final int codeInt = code is int ? code : (code is double ? code.toInt() : 0);
    return weatherCodes[codeInt] ?? '未知';
  }

  IconData _getWeatherIcon(dynamic code) {
    final int codeInt = code is int ? code : (code is double ? code.toInt() : 0);
    if (codeInt == 0) return Icons.wb_sunny;
    if (codeInt <= 3) return Icons.cloud;
    if (codeInt <= 48) return Icons.foggy;
    if (codeInt <= 67) return Icons.water_drop;
    if (codeInt <= 77) return Icons.ac_unit;
    if (codeInt <= 82) return Icons.grain;
    return Icons.thunderstorm;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final Color textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final Color textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;

    if (!_isInitialized) {
      return SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final date = '${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[now.weekday % 7];
    
    final lunarDate = Lunar.fromDate(now);
    final lunarMonth = '${lunarDate.getMonthInChinese()}月';
    final lunarDay = lunarDate.getDayInChinese();
    final lunarGanZhiYear = lunarDate.getYearInGanZhi();
    final lunarFullString = '$lunarGanZhiYear年$lunarMonth$lunarDay';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateCard(
                date: date,
                weekday: weekday,
                lunarDate: lunarFullString,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16.0),
              _buildWeatherCard(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16.0),
              _buildForecastCard(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16.0),
              _buildCalendarCard(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String date,
    required String weekday,
    required String lunarDate,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 32.0,
            spreadRadius: 8.0,
          ),
        ],
      ),
      child: isLargeScreen
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$date$weekday',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '·',
                    style: TextStyle(
                      fontSize: 28.0,
                      color: textSecondary,
                    ),
                  ),
                ),
                Text(
                  lunarDate,
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  '$date$weekday',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  lunarDate,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeatherCard({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 32.0,
            spreadRadius: 8.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '天气',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: textSecondary),
                onPressed: _fetchWeather,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (_isLoadingWeather)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
              ),
            )
          else if (_weatherError != null)
            Center(
              child: Text(
                _weatherError!,
                style: TextStyle(
                  color: isDarkMode ? Colors.redAccent : Colors.red,
                  fontSize: 14.0,
                ),
              ),
            )
          else if (_weatherData != null)
            _buildWeatherContent(textPrimary, textSecondary, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(Color textPrimary, Color textSecondary, bool isDarkMode) {
    final current = _weatherData!['current'];
    final daily = _weatherData!['daily'];
    final temp = double.tryParse(current['temperature_2m'].toString()) ?? 0.0;
    final code = current['weather_code'];
    final windSpeed = double.tryParse(current['wind_speed_10m'].toString()) ?? 0.0;
    final humidity = double.tryParse(current['relative_humidity_2m'].toString()) ?? 0;
    final apparentTemp = double.tryParse(current['apparent_temperature'].toString()) ?? temp;
    final pressure = double.tryParse(current['pressure_msl'].toString()) ?? 0;
    final isDay = current['is_day'] == 1;
    
    final uvIndexList = daily['uv_index_max'] as List?;
    final precipitationList = daily['precipitation_sum'] as List?;
    
    final uvIndex = uvIndexList != null && uvIndexList.isNotEmpty ? double.tryParse(uvIndexList[0].toString()) ?? 0.0 : 0.0;
    final precipitation = precipitationList != null && precipitationList.isNotEmpty ? double.tryParse(precipitationList[0].toString()) ?? 0.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getWeatherIcon(code),
              size: 48.0,
              color: textPrimary,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    _getWeatherDescription(code),
                    style: TextStyle(
                      fontSize: 16.0,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        _buildWeatherDetailRow(
          icon: Icons.thermostat,
          label: '体感温度',
          value: '${apparentTemp.toStringAsFixed(1)}°C',
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: Icons.water_drop,
          label: '湿度',
          value: '${humidity.toStringAsFixed(0)}%',
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: Icons.air,
          label: '风速',
          value: '${windSpeed.toStringAsFixed(1)} km/h',
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: Icons.compress,
          label: '气压',
          value: '${pressure.toStringAsFixed(0)} hPa',
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: Icons.wb_sunny,
          label: '紫外线指数',
          value: _getUVIndexDescription(uvIndex),
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: Icons.grain,
          label: '降水量',
          value: '${precipitation.toStringAsFixed(1)} mm',
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 12.0),
        _buildWeatherDetailRow(
          icon: isDay ? Icons.light_mode : Icons.nightlight_round,
          label: isDay ? '白天' : '夜晚',
          value: '',
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  Widget _buildWeatherDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.0,
          color: textSecondary,
        ),
        const SizedBox(width: 12.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: textSecondary,
          ),
        ),
        const Spacer(),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
      ],
    );
  }

  String _getUVIndexDescription(double uvIndex) {
    if (uvIndex <= 2) return '${uvIndex.toStringAsFixed(1)} (低)';
    if (uvIndex <= 5) return '${uvIndex.toStringAsFixed(1)} (中等)';
    if (uvIndex <= 7) return '${uvIndex.toStringAsFixed(1)} (高)';
    if (uvIndex <= 10) return '${uvIndex.toStringAsFixed(1)} (很高)';
    return '${uvIndex.toStringAsFixed(1)} (极高)';
  }

  Widget _buildForecastCard({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    if (_weatherData == null) return const SizedBox.shrink();

    final daily = _weatherData!['daily'];
    final times = daily['time'] as List?;
    final maxTemps = daily['temperature_2m_max'] as List?;
    final minTemps = daily['temperature_2m_min'] as List?;
    final weatherCodes = daily['weather_code'] as List?;
    final precipitationSums = daily['precipitation_sum'] as List?;

    if (times == null || maxTemps == null || minTemps == null || weatherCodes == null || precipitationSums == null) {
      return const SizedBox.shrink();
    }

    final forecastDays = 5;
    final startIndex = 1;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 32.0,
            spreadRadius: 8.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '未来5天',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          ...List.generate(forecastDays, (index) {
            final dataIndex = startIndex + index;
            if (dataIndex >= times.length || dataIndex >= maxTemps.length || 
                dataIndex >= minTemps.length || dataIndex >= weatherCodes.length ||
                dataIndex >= precipitationSums.length) {
              return const SizedBox.shrink();
            }
            
            final dateStr = times[dataIndex];
            if (dateStr == null) return const SizedBox.shrink();
            
            final date = DateTime.parse(dateStr);
            final maxTemp = double.tryParse(maxTemps[dataIndex].toString()) ?? 0;
            final minTemp = double.tryParse(minTemps[dataIndex].toString()) ?? 0;
            final code = weatherCodes[dataIndex] ?? 0;
            final precipitation = double.tryParse(precipitationSums[dataIndex].toString()) ?? 0;
            
            final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
            final weekday = weekdays[date.weekday - 1];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 60.0,
                    child: Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _getWeatherIcon(code),
                    size: 24.0,
                    color: textPrimary,
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    _getWeatherDescription(code),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (precipitation > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.grain,
                        size: 16.0,
                        color: textSecondary,
                      ),
                    ),
                  Text(
                    '${maxTemp.toStringAsFixed(0)}° / ${minTemp.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarCard({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 768;
    
    final daysInMonth = lastDayOfMonth.day;
    final Map<int, String> lunarMap = {};
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final lunar = Lunar.fromDate(date);
      final lunarDay = lunar.getDayInChinese();
      lunarMap[day] = lunarDay;
    }

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 32.0 : 24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 32.0,
            spreadRadius: 8.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${now.month}月',
            style: TextStyle(
              fontSize: isLargeScreen ? 24.0 : 20.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          SizedBox(height: isLargeScreen ? 20.0 : 16.0),
          _buildWeekdayHeader(textSecondary, isLargeScreen),
          SizedBox(height: isLargeScreen ? 12.0 : 8.0),
          _buildCalendarGrid(
            firstDayOfMonth: firstDayOfMonth,
            lastDayOfMonth: lastDayOfMonth,
            startWeekday: startWeekday,
            currentDay: now.day,
            lunarMap: lunarMap,
            isLargeScreen: isLargeScreen,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(Color textSecondary, bool isLargeScreen) {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: isLargeScreen ? 48.0 : 32.0,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: isLargeScreen ? 16.0 : 14.0,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid({
    required DateTime firstDayOfMonth,
    required DateTime lastDayOfMonth,
    required int startWeekday,
    required int currentDay,
    required Map<int, String> lunarMap,
    required bool isLargeScreen,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((startWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: List.generate(totalCells ~/ 7, (weekIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: isLargeScreen ? 12.0 : 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - (startWeekday - 1) + 1;
              final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
              final isToday = isValidDay && dayNumber == currentDay;
              final lunarDay = isValidDay ? lunarMap[dayNumber] : '';

              return SizedBox(
                width: isLargeScreen ? 48.0 : 32.0,
                height: isLargeScreen ? 48.0 : 32.0,
                child: Center(
                  child: isValidDay
                      ? Container(
                          padding: isToday
                              ? EdgeInsets.symmetric(horizontal: isLargeScreen ? 10.0 : 5.0)
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDarkMode 
                                    ? Colors.blue.withValues(alpha: 0.8)
                                    : Colors.blue.withValues(alpha: 1.0))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(isLargeScreen ? 12.0 : 8.0),
                            border: isToday
                                ? Border.all(
                                    color: isDarkMode 
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.blue.withValues(alpha: 0.3),
                                    width: 2.0,
                                  )
                                : null,
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: isDarkMode 
                                          ? Colors.blue.withValues(alpha: 0.4)
                                          : Colors.blue.withValues(alpha: 0.2),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 14.0 : 12.0,
                                  color: isToday
                                      ? Colors.white
                                      : textPrimary,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (lunarDay != null && lunarDay!.isNotEmpty)
                                Text(
                                  lunarDay!,
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 10.0 : 8.0,
                                    color: isToday
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
