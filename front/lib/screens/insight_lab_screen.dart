import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../services/favorites_service.dart';
import '../models/team_insight.dart';
import 'insight_tabs/hot_streaks_tab.dart';
import 'insight_tabs/form_tracker_tab.dart';
import 'insight_tabs/favorites_trends_tab.dart';

/// Insight Lab - аналітичний центр з трендами команд
class InsightLabScreen extends StatefulWidget {
  const InsightLabScreen({super.key});

  @override
  State<InsightLabScreen> createState() => _InsightLabScreenState();
}

class _InsightLabScreenState extends State<InsightLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InsightsService _insightsService = InsightsService();
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshInsights() async {
    // Очистити кеш і перерахувати
    await _insightsService.clearCache();
    setState(() {}); // Оновити UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ACEF2),
        automaticallyImplyLeading: false,
        title: const Text(
          'Insight lab',
          style: TextStyle(
            color: Color(0xFF0F265C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshInsights,
            icon: const Icon(Icons.refresh, color: Color(0xFF0F265C)),
            tooltip: 'Refresh insights',
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F265C),
              unselectedLabelColor: const Color(0xFF6B9EB8),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Lato',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
              indicatorColor: const Color(0xFF0F265C),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'HOT STREAKS'),
                Tab(text: 'FORM TRACKER'),
                Tab(text: 'FAVORITES TRENDS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HotStreaksTab(),
          FormTrackerTab(),
          FavoritesTrendsTab(),
        ],
      ),
    );
  }
}