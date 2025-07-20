import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 24),

            // Charts
            _buildCharts(),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final stats = [
      {
        'title': 'إجمالي الزيارات',
        'value': '12,456',
        'change': '+15%',
        'color': Colors.blue,
      },
      {
        'title': 'المستخدمين النشطين',
        'value': '2,341',
        'change': '+8%',
        'color': Colors.green,
      },
      {
        'title': 'الحجوزات',
        'value': '1,234',
        'change': '+23%',
        'color': Colors.orange,
      },
      {
        'title': 'الإيرادات',
        'value': '45,678 ريال',
        'change': '+12%',
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: stat['color'] as Color,
                      size: 24,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stat['change'] as String,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائيات الزيارات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'الزيارات الشهرية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const titles = [
                                'يناير',
                                'فبراير',
                                'مارس',
                                'أبريل',
                                'مايو',
                                'يونيو',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < titles.length) {
                                return Text(titles[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 5),
                            FlSpot(2, 4),
                            FlSpot(3, 7),
                            FlSpot(4, 6),
                            FlSpot(5, 8),
                          ],
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النشاط الأخير',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final activities = [
                {
                  'action': 'زيارة جديدة',
                  'user': 'أحمد محمد',
                  'time': 'منذ 5 دقائق',
                },
                {
                  'action': 'حجز جديد',
                  'user': 'فاطمة علي',
                  'time': 'منذ 15 دقيقة',
                },
                {
                  'action': 'تسجيل مستخدم',
                  'user': 'محمد حسن',
                  'time': 'منذ ساعة',
                },
                {
                  'action': 'مراجعة جديدة',
                  'user': 'سارة أحمد',
                  'time': 'منذ ساعتين',
                },
                {
                  'action': 'دفع مكتمل',
                  'user': 'علي محمد',
                  'time': 'منذ 3 ساعات',
                },
              ];

              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(activity['action'] as String),
                subtitle: Text('${activity['user']} - ${activity['time']}'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }
}
