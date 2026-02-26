import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_launcher/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';

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
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('zh_CN', '');
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _fetchWeather();
    }
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoadingWeather = false;
        });
      } else {
        setState(() {
          _weatherError = 'Failed to load weather';
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _weatherError = 'Error: $e';
        _isLoadingWeather = false;
      });
    }
  }

  String _getWeatherDescription(int code) {
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
    return weatherCodes[code] ?? '未知';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.foggy;
    if (code <= 67) return Icons.water_drop;
    if (code <= 77) return Icons.ac_unit;
    if (code <= 82) return Icons.grain;
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
    final dateFormatter = DateFormat('yyyy年MM月dd日');
    final weekdayFormatter = DateFormat('EEEE', 'zh_CN');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateCard(
                date: dateFormatter.format(now),
                weekday: weekdayFormatter.format(now),
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
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
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
        children: [
          Text(
            date,
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            weekday,
            style: TextStyle(
              fontSize: 20.0,
              color: textSecondary,
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
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
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
            _buildWeatherContent(textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(Color textPrimary, Color textSecondary) {
    final current = _weatherData!['current'];
    final temp = current['temperature_2m'];
    final code = current['weather_code'];
    final windSpeed = current['wind_speed_10m'];

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
            Text(
              '${temp.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          _getWeatherDescription(code),
          style: TextStyle(
            fontSize: 18.0,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          '风速: ${windSpeed.toStringAsFixed(1)} km/h',
          style: TextStyle(
            fontSize: 14.0,
            color: textSecondary,
          ),
        ),
      ],
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

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
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
            '${now.year}年${now.month}月',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildWeekdayHeader(textSecondary),
          const SizedBox(height: 8.0),
          _buildCalendarGrid(
            firstDayOfMonth: firstDayOfMonth,
            lastDayOfMonth: lastDayOfMonth,
            startWeekday: startWeekday,
            currentDay: now.day,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(Color textSecondary) {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 32.0,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14.0,
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
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((startWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: List.generate(totalCells ~/ 7, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - (startWeekday - 1) + 1;
              final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
              final isToday = isValidDay && dayNumber == currentDay;

              return SizedBox(
                width: 32.0,
                height: 32.0,
                child: Center(
                  child: isValidDay
                      ? Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDarkMode 
                                    ? Colors.blue.withValues(alpha: 0.6)
                                    : Colors.blue.withValues(alpha: 0.8))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: isToday
                                    ? Colors.white
                                    : textPrimary,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
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
