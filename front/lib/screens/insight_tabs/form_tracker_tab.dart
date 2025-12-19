import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ← ДОДАНО
import 'dart:math' as math;
import '../../services/insights_service.dart';
import '../../services/nhl_api_service.dart';
import '../../models/team_insight.dart';

/// Tab 2: Form Tracker - графіки форми команди
class FormTrackerTab extends StatefulWidget {
  const FormTrackerTab({super.key});

  @override
  State<FormTrackerTab> createState() => _FormTrackerTabState();
}

class _FormTrackerTabState extends State<FormTrackerTab> {
  final InsightsService _insightsService = InsightsService();
  final NHLApiService _apiService = NHLApiService();

  List<Map<String, dynamic>> _allTeams = [];
  int? _selectedTeamId;
  TeamInsight? _teamInsight;
  bool _isLoadingTeams = true;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoadingTeams = true);

    try {
      final teams = await _apiService.getAllTeams();

      if (mounted) {
        setState(() {
          _allTeams = teams;
          _isLoadingTeams = false;
        });
      }
    } catch (e) {
      print('Error loading teams: $e');
      if (mounted) {
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  Future<void> _selectTeam(int teamId) async {
    setState(() {
      _selectedTeamId = teamId;
      _isLoadingStats = true;
    });

    try {
      final insight = await _insightsService.getTeamInsight(teamId, gamesRange: 10);

      if (mounted) {
        setState(() {
          _teamInsight = insight;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading team stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedTeamId = null;
      _teamInsight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTeamSelector(),
        Expanded(
          child: _isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : _teamInsight == null
              ? _buildEmptyState()
              : _buildCharts(),
        ),
      ],
    );
  }

  Widget _buildTeamSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          _isLoadingTeams
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<int>(
            value: _selectedTeamId,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE8F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: const Text('Pick a game'),
            items: _allTeams.map((team) {
              return DropdownMenuItem<int>(
                value: team['id'] as int,
                child: Text(
                  team['name'] as String,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Lato'),
                ),
              );
            }).toList(),
            onChanged: (teamId) {
              if (teamId != null) {
                _selectTeam(teamId);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    if (_teamInsight == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeamHeader(),
          const SizedBox(height: 24),
          _buildChart(
            title: 'Points per game',
            child: _buildLineChart(
              _teamInsight!.pointsPerGame,
              maxY: 3.0,
              color: const Color(0xFF3498DB),
            ),
          ),
          const SizedBox(height: 24),
          _buildChart(
            title: 'Goals for / Goals against',
            child: _buildDualLineChart(
              _teamInsight!.goalsFor.map((g) => g.toDouble()).toList(),
              _teamInsight!.goalsAgainst.map((g) => g.toDouble()).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildChart(
            title: 'Shots vs opponent shots',
            child: _buildBarChart(
              _teamInsight!.shotsFor,
              _teamInsight!.shotsAgainst,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() {
    final Map<String, dynamic> teamData = _allTeams
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (t) => t['id'] == _teamInsight?.teamId,
      orElse: () => <String, dynamic>{},
    );

    final String division = teamData['division']?.toString() ?? teamData['divisionName']?.toString() ?? 'NHL';
    final String conference = teamData['conference']?.toString() ?? teamData['conferenceName']?.toString() ?? '';
    final String locationInfo = conference.isNotEmpty ? '$division Division | $conference' : '$division Division';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ✅ ВИПРАВЛЕННЯ: Logo з підтримкою SVG і PNG
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildTeamLogo(_teamInsight!.teamLogo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamInsight!.teamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  locationInfo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // ✅ НОВИЙ МЕТОД: Відображення логотипу з підтримкою SVG і PNG
  Widget _buildTeamLogo(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return const Icon(Icons.sports_hockey, color: Color(0xFF6B9EB8));
    }

    // Очищаємо URL від query параметрів
    String cleanUrl = logoUrl;
    if (cleanUrl.contains('?')) {
      cleanUrl = cleanUrl.split('?').first;
    }

    // Визначаємо формат
    final isSVG = cleanUrl.toLowerCase().endsWith('.svg');
    final isPNG = cleanUrl.toLowerCase().endsWith('.png');

    if (isSVG) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.network(
          cleanUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (isPNG) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          cleanUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
          errorBuilder: (_, __, ___) => const Icon(Icons.sports_hockey, color: Color(0xFF6B9EB8)),
        ),
      );
    }

    return const Icon(Icons.sports_hockey, color: Color(0xFF6B9EB8));
  }

  Widget _buildChart({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart(List<double> data, {required double maxY, required Color color}) {
    if (data.isEmpty) return const SizedBox(height: 150);

    return SizedBox(
      height: 150,
      child: CustomPaint(
        size: const Size(double.infinity, 150),
        painter: LineChartPainter(
          data: data,
          maxY: maxY,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDualLineChart(List<double> dataFor, List<double> dataAgainst) {
    if (dataFor.isEmpty || dataAgainst.isEmpty) return const SizedBox(height: 150);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: CustomPaint(
            size: const Size(double.infinity, 150),
            painter: DualLineChartPainter(
              dataFor: dataFor,
              dataAgainst: dataAgainst,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('GF', const Color(0xFF3498DB)),
            const SizedBox(width: 16),
            _buildLegendItem('GA', const Color(0xFFE74C3C)),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(List<int> dataFor, List<int> dataAgainst) {
    if (dataFor.isEmpty || dataAgainst.isEmpty) return const SizedBox(height: 200);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: const Size(double.infinity, 200),
            painter: BarChartPainter(
              dataFor: dataFor.map((i) => i.toDouble()).toList(),
              dataAgainst: dataAgainst.map((i) => i.toDouble()).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('SOG', const Color(0xFF3498DB)),
            const SizedBox(width: 16),
            _buildLegendItem('Opp SOG', const Color(0xFFE74C3C)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B9EB8),
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_hockey,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a team to see statistics',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}

// === CUSTOM PAINTERS (без змін) ===

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxY;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] / maxY).clamp(0.0, 1.0);
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] / maxY).clamp(0.0, 1.0);
      final y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DualLineChartPainter extends CustomPainter {
  final List<double> dataFor;
  final List<double> dataAgainst;

  DualLineChartPainter({
    required this.dataFor,
    required this.dataAgainst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataFor.isEmpty || dataAgainst.isEmpty) return;

    final maxValue = math.max(
      dataFor.reduce(math.max),
      dataAgainst.reduce(math.max),
    );

    _drawFilledArea(canvas, size, dataFor, maxValue, const Color(0xFF3498DB).withOpacity(0.3));
    _drawFilledArea(canvas, size, dataAgainst, maxValue, const Color(0xFFE74C3C).withOpacity(0.3));

    _drawLine(canvas, size, dataFor, maxValue, const Color(0xFF3498DB));
    _drawLine(canvas, size, dataAgainst, maxValue, const Color(0xFFE74C3C));
  }

  void _drawFilledArea(Canvas canvas, Size size, List<double> data, double maxValue, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final double normalizedY = maxValue == 0 ? 0.0 : (data[i] / maxValue).toDouble().clamp(0.0, 1.0);
      final y = size.height - (normalizedY * size.height);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, double maxValue, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final double normalizedY = maxValue == 0 ? 0.0 : (data[i] / maxValue).toDouble().clamp(0.0, 1.0);
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<double> dataFor;
  final List<double> dataAgainst;

  BarChartPainter({
    required this.dataFor,
    required this.dataAgainst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataFor.isEmpty || dataAgainst.isEmpty) return;

    final maxValue = math.max(
      dataFor.reduce(math.max),
      dataAgainst.reduce(math.max),
    );

    final barWidth = (size.width / dataFor.length) * 0.35;
    final stepX = size.width / dataFor.length;

    for (int i = 0; i < dataFor.length; i++) {
      final centerX = i * stepX + stepX / 2;

      final forHeight = maxValue == 0 ? 0.0 : (dataFor[i] / maxValue) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          size.height - forHeight,
          barWidth,
          forHeight,
        ),
        Paint()..color = const Color(0xFF3498DB),
      );

      final againstHeight = maxValue == 0 ? 0.0 : (dataAgainst[i] / maxValue) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(
          centerX + 2,
          size.height - againstHeight,
          barWidth,
          againstHeight,
        ),
        Paint()..color = const Color(0xFFE74C3C),
      );
    }

    for (int i = 0; i < dataFor.length; i++) {
      final centerX = i * stepX + stepX / 2;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B9EB8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, size.height + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}