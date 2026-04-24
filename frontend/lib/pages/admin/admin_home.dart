import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/admin/admin_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<double> dailyReservations = List.filled(7, 0);
  List<double> monthlyReservations = List.filled(12, 0);
  List<double> monthlyRevenue = List.filled(12, 0);
  List<double> hourlyEarnings = List.filled(24, 0);
  double totalEarningsToday = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      const baseUrl = "http://garage.flash-ware.com:3000/admin";

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token');

      if (token == null) {
        throw Exception("No admin token found");
      }

      // Weekly Reservations
      final weeklyResResponse = await http.get(
        Uri.parse("$baseUrl/stats/weekly-reservations"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (weeklyResResponse.statusCode == 200) {
        final data = json.decode(weeklyResResponse.body);
        final days = [
          "Saturday",
          "Sunday",
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
        ];
        final counts = List<double>.filled(7, 0);

        for (var entry in data['weeklyReservations']) {
          int index = days.indexOf(entry['day']);
          if (index != -1) {
            counts[index] = (entry['count'] as num).toDouble();
          }
        }
        dailyReservations = counts;
      }

      // Monthly Reservations
      final monthlyResResponse = await http.get(
        Uri.parse("$baseUrl/stats/monthly-reservations"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (monthlyResResponse.statusCode == 200) {
        final data = json.decode(monthlyResResponse.body);
        final counts = List<double>.filled(12, 0);

        for (var entry in data['monthlyBreakdown']) {
          final monthString = entry['month'];
          final monthIndex = int.parse(monthString.split("-")[1]) - 1;
          if (monthIndex >= 0 && monthIndex < 12) {
            counts[monthIndex] = (entry['count'] as num).toDouble();
          }
        }
        monthlyReservations = counts;
      }

      // Monthly Revenue
      final monthlyRevResponse = await http.get(
        Uri.parse("$baseUrl/stats/monthly-revenue"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (monthlyRevResponse.statusCode == 200) {
        final data = json.decode(monthlyRevResponse.body);
        final revenues = List<double>.filled(12, 0);

        for (var entry in data['monthlyRevenue']) {
          final monthString = entry['month'];
          final monthIndex = int.parse(monthString.split("-")[1]) - 1;
          if (monthIndex >= 0 && monthIndex < 12) {
            revenues[monthIndex] = (entry['totalRevenue'] as num).toDouble();
          }
        }
        monthlyRevenue = revenues;
      }

      // Earnings Today
      final todayEarningsResponse = await http.get(
        Uri.parse("$baseUrl/stats/earnings-today"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (todayEarningsResponse.statusCode == 200) {
        final data = json.decode(todayEarningsResponse.body);
        totalEarningsToday = (data['totalEarningsToday'] as num).toDouble();

        final earningsBlocks = data['earningsByBlock'] as List;
        final hourly = List<double>.filled(24, 0);

        for (var block in earningsBlocks) {
          final blockLabel = block['block'];
          final amount = (block['totalRevenue'] as num).toDouble();

          int startHour = int.parse(blockLabel.replaceAll("h", ""));
          for (int i = startHour; i < startHour + 4 && i < 24; i++) {
            hourly[i] = amount / 4;
          }
        }
        hourlyEarnings = hourly;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF25303B),
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    final totalEarnings = totalEarningsToday;
    final maxDailyReservations = dailyReservations;
    final monthlyParkingRevenue = monthlyRevenue;
    final monthlyReservationsData = monthlyReservations;
    final hourlyEarningsData = hourlyEarnings;

    return Scaffold(
      backgroundColor: const Color(0xFF25303B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF25303B),
        elevation: 0,
        title: const Text(
          'GARAGE EZway',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTotalEarningsCard(totalEarnings),
                    const SizedBox(height: 20),
                    _buildChartCard(
                      'Daily Reservations',
                      _buildDailyReservationsChart(maxDailyReservations),
                    ),
                    _buildChartCard(
                      'Monthly Parking Revenue',
                      _buildMonthlyParkingRevenueChart(monthlyParkingRevenue),
                    ),
                    _buildChartCard(
                      'Monthly Reservations',
                      _buildMonthlyReservationsChart(monthlyReservationsData),
                    ),
                    _buildChartCard(
                      'Hourly Earnings',
                      _buildHourlyEarningsChart(hourlyEarningsData),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AdminNavBar(currentPage: 'home'),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(double totalEarnings) {
    return Card(
      color: const Color(0xFF3A4A5A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Total Earnings Today",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${totalEarnings.toStringAsFixed(2)} LE",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      color: const Color(0xFF3A4A5A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 200, width: double.infinity, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReservationsChart(List<double> data) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];
                return Text(
                  days[value.toInt()],
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              interval: 20,
              reservedSize: 30,
            ),
          ),
        ),
        maxY: 120,
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                color: Colors.tealAccent,
                width: 22,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyParkingRevenueChart(List<double> data) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final interval = (maxValue / 5).ceilToDouble();
    final safeInterval = interval == 0 ? 1.0 : interval;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final months = [
                  "Jan",
                  "Feb",
                  "Mar",
                  "Apr",
                  "May",
                  "Jun",
                  "Jul",
                  "Aug",
                  "Sep",
                  "Oct",
                  "Nov",
                  "Dec",
                ];
                if (value.toInt() % 2 == 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              interval: safeInterval,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index]),
            ),
            isCurved: true,
            color: Colors.tealAccent,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.tealAccent.withAlpha(76),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxValue + safeInterval,
      ),
    );
  }

  Widget _buildMonthlyReservationsChart(List<double> data) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final months = [
                  "Jan",
                  "Feb",
                  "Mar",
                  "Apr",
                  "May",
                  "Jun",
                  "Jul",
                  "Aug",
                  "Sep",
                  "Oct",
                  "Nov",
                  "Dec",
                ];
                if (value.toInt() % 2 == 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              interval: 50,
              reservedSize: 30,
            ),
          ),
        ),
        maxY: 150,
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: data[index],
                color: Colors.tealAccent,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHourlyEarningsChart(List<double> data) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0 && hour >= 0 && hour < 24) {
                  return Text(
                    "${hour}h",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              getTitlesWidget:
                  (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: data.reduce((a, b) => a > b ? a : b) + 50,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i]),
            ),
            color: Colors.tealAccent,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.tealAccent.withAlpha(76),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
