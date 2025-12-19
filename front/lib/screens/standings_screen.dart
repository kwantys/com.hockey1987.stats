import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/team_standing.dart';
import '../models/team_models.dart';
import '../services/nhl_api_service.dart';
import '../services/standings_cache_service.dart'; // ← ДОДАНО
import 'team_profile_screen.dart';

/// Standings Screen - турнірні таблиці NHL з кешуванням
class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();

  List<TeamStanding> _allStandings = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdateTime; // ← ДОДАНО
  bool _isLoadingFromCache = false; // ← ДОДАНО

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStandings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ ОНОВЛЕНИЙ МЕТОД з кешуванням
  Future<void> _loadStandings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // КРОК 1: Спробувати завантажити з кешу
      print('🔍 Checking standings cache...');
      final cachedData = await StandingsCacheService.getCachedStandings();

      if (cachedData != null) {
        // Кеш знайдено - використовуємо його
        print('✅ Using cached standings');

        final lastUpdate = await StandingsCacheService.getLastUpdateTime();
        final standings = _parseStandingsFromCache(cachedData);

        if (mounted) {
          setState(() {
            _allStandings = standings;
            _lastUpdateTime = lastUpdate;
            _isLoading = false;
            _isLoadingFromCache = true;
          });
        }

        print('✅ Loaded ${standings.length} teams from cache');

        // Опціонально: оновити у фоні якщо кеш старий
        final cacheAge = await StandingsCacheService.getCacheAge();
        if (cacheAge != null && cacheAge > Duration(hours: 3)) {
          print('🔄 Cache is old, refreshing in background...');
          _refreshStandingsInBackground();
        }

        return;
      }

      // КРОК 2: Кешу немає - завантажуємо з API
      print('📡 No valid cache, loading from API...');
      await _loadFromAPI();
    } catch (e) {
      print('❌ Error loading standings: $e');
      await _loadExpiredCache();
    }
  }

  /// Завантаження з API
  Future<void> _loadFromAPI() async {
    final standings = await _apiService.getStandings();

    // Зберігаємо raw дані для кешу
    final standingsData = {'standings': standings.map((t) => t.toJson()).toList()};

    if (mounted) {
      setState(() {
        _allStandings = standings;
        _lastUpdateTime = DateTime.now();
        _isLoading = false;
        _isLoadingFromCache = false;
      });
    }

    print('✅ Loaded ${standings.length} teams from API');

    // Зберігаємо в кеш
    await StandingsCacheService.cacheStandings(standingsData);
  }

  /// Фонове оновлення
  Future<void> _refreshStandingsInBackground() async {
    try {
      await _loadFromAPI();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Standings updated'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Background refresh failed: $e');
      // Тихо ігноруємо помилку
    }
  }

  /// Завантаження застарілого кешу (offline режим)
  Future<void> _loadExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final standingsJson = prefs.getString('standings_cache_data');

      if (standingsJson != null) {
        final standingsData = json.decode(standingsJson);
        final standings = _parseStandingsFromCache(standingsData);
        final lastUpdate = await StandingsCacheService.getLastUpdateTime();

        if (mounted) {
          setState(() {
            _allStandings = standings;
            _lastUpdateTime = lastUpdate;
            _isLoading = false;
            _isLoadingFromCache = true;
            _errorMessage = 'Showing cached data (offline mode)';
          });
        }

        print('✅ Loaded expired cache (offline mode)');
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load standings. Check internet connection.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load standings. Check internet connection.';
        });
      }
    }
  }

  /// Парсинг standings з кешу
  List<TeamStanding> _parseStandingsFromCache(Map<String, dynamic> cachedData) {
    final standingsList = cachedData['standings'] as List? ?? [];
    final List<TeamStanding> teams = [];

    for (var teamData in standingsList) {
      try {
        teams.add(TeamStanding.fromJson(teamData));
      } catch (e) {
        print('Error parsing team: $e');
      }
    }

    return teams;
  }

  /// Примусове оновлення
  Future<void> _forceRefresh() async {
    await StandingsCacheService.clearCache();
    await _loadStandings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standings refreshed'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Форматування часу оновлення
  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8ACEF2),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'League Tables',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
            // ✅ Індикатор останнього оновлення
            if (_lastUpdateTime != null)
              Text(
                'Updated: ${_formatUpdateTime(_lastUpdateTime!)}',
                style: const TextStyle(
                  color: Color(0xFF0F265C),
                  fontSize: 11,
                  fontFamily: 'Lato',
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _forceRefresh,
            icon: const Icon(Icons.refresh, color: Color(0xFF0F265C)),
            tooltip: 'Refresh standings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F265C),
              unselectedLabelColor: const Color(0xFF6B9EB8),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Lato',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
              indicatorColor: const Color(0xFF0F265C),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'WILD CARD'),
                Tab(text: 'DIVISION'),
                Tab(text: 'LEAGUE'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ✅ Банер для кешованих даних
          if (_isLoadingFromCache && _lastUpdateTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.cached, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing cached data from ${_formatUpdateTime(_lastUpdateTime!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: _forceRefresh,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _allStandings.isEmpty
                ? _buildErrorState()
                : TabBarView(
              controller: _tabController,
              children: [
                _buildWildCardTab(),
                _buildDivisionTab(),
                _buildLeagueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWildCardTab() {
    final easternTeams = _allStandings
        .where((t) => t.conferenceName.toLowerCase().contains('eastern'))
        .toList();
    final westernTeams = _allStandings
        .where((t) => t.conferenceName.toLowerCase().contains('western'))
        .toList();

    easternTeams.sort(_compareTeams);
    westernTeams.sort(_compareTeams);

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: const Color(0xFF0F265C),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (easternTeams.isNotEmpty) ...[
            _buildConferenceHeader('Eastern Conference'),
            _buildStandingsTable(easternTeams, showWildCard: true),
            const SizedBox(height: 24),
          ],
          if (westernTeams.isNotEmpty) ...[
            _buildConferenceHeader('Western Conference'),
            _buildStandingsTable(westernTeams, showWildCard: true),
          ],
          if (easternTeams.isEmpty && westernTeams.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildDivisionTab() {
    final divisions = <String, List<TeamStanding>>{};
    for (var team in _allStandings) {
      divisions.putIfAbsent(team.divisionName, () => []).add(team);
    }

    for (var teams in divisions.values) {
      teams.sort(_compareTeams);
    }

    final divisionOrder = ['Atlantic', 'Metropolitan', 'Central', 'Pacific'];
    final sortedDivisions = divisionOrder
        .where((name) => divisions.containsKey(name))
        .toList();

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: const Color(0xFF0F265C),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...sortedDivisions.map((divName) {
            return Column(
              children: [
                _buildDivisionHeader(divName),
                _buildStandingsTable(divisions[divName]!),
                const SizedBox(height: 24),
              ],
            );
          }),
          if (sortedDivisions.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildLeagueTab() {
    final sortedTeams = List<TeamStanding>.from(_allStandings);
    sortedTeams.sort(_compareTeams);

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: const Color(0xFF0F265C),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStandingsTable(sortedTeams, showRank: true),
          if (sortedTeams.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildConferenceHeader(String conferenceName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        conferenceName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F265C),
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildDivisionHeader(String divisionName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$divisionName Division',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F265C),
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildStandingsTable(
      List<TeamStanding> teams, {
        bool showWildCard = false,
        bool showRank = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE8F4F8)),
          ...teams.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final position = index + 1;

            String? status;
            if (showWildCard) {
              if (position <= 3) {
                status = 'playoff';
              } else if (position <= 5) {
                status = 'wildcard';
              }
            }

            return _buildTeamRow(
              team,
              position: showRank ? position : null,
              status: status,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _buildHeaderCell('Pos', width: 40),
          _buildHeaderCell('Team', flex: 3),
          _buildHeaderCell('GP', width: 35),
          _buildHeaderCell('W', width: 30),
          _buildHeaderCell('L', width: 30),
          _buildHeaderCell('OTL', width: 35),
          _buildHeaderCell('PTS', width: 40),
          _buildHeaderCell('GF', width: 35),
          _buildHeaderCell('GA', width: 35),
          _buildHeaderCell('Diff', width: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int? flex, double? width}) {
    final child = Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B9EB8),
        fontFamily: 'Lato',
      ),
      textAlign: TextAlign.center,
    );

    if (flex != null) {
      return Expanded(flex: flex, child: child);
    } else if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }

  Widget _buildTeamRow(
      TeamStanding team, {
        int? position,
        String? status,
      }) {
    return InkWell(
      onTap: () {
        print('=== TEAM TAP DEBUG ===');
        print('Team ID: ${team.teamId}');
        print('Team Name: ${team.teamName}');
        print('====================');

        if (team.teamId == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Team ID is 0. Cannot open profile.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamProfileScreen(
              teamId: team.teamId,
              team: Team(
                teamId: team.teamId,
                teamName: team.teamName,
                teamAbbrev: team.teamAbbrev,
                teamLogo: team.teamLogo,
                divisionName: team.divisionName,
                conferenceName: team.conferenceName,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: const Color(0xFFE8F4F8).withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      position?.toString() ?? team.divisionRank?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F265C),
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                team.teamAbbrev,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
            ),
            _buildStatCell(team.gamesPlayed.toString(), width: 35),
            _buildStatCell(team.wins.toString(), width: 30),
            _buildStatCell(team.losses.toString(), width: 30),
            _buildStatCell(team.overtimeLosses.toString(), width: 35),
            _buildStatCell(team.points.toString(), width: 40, bold: true),
            _buildStatCell(team.goalsFor.toString(), width: 35),
            _buildStatCell(team.goalsAgainst.toString(), width: 35),
            _buildStatCell(
              _formatDiff(team.goalDifferential),
              width: 40,
              color: _getDiffColor(team.goalDifferential),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(
      String text, {
        double? width,
        bool bold = false,
        Color? color,
      }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF0F265C),
          fontFamily: 'Lato',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'playoff':
        return Colors.green;
      case 'wildcard':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatDiff(int diff) {
    if (diff > 0) return '+$diff';
    return diff.toString();
  }

  Color _getDiffColor(int diff) {
    if (diff > 0) return Colors.green;
    if (diff < 0) return Colors.red;
    return const Color(0xFF0F265C);
  }

  int _compareTeams(TeamStanding a, TeamStanding b) {
    if (a.points != b.points) {
      return b.points.compareTo(a.points);
    }
    if (a.regulationWins != b.regulationWins) {
      return b.regulationWins.compareTo(a.regulationWins);
    }
    return b.goalDifferential.compareTo(a.goalDifferential);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Standings are unavailable right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try again later.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _forceRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F265C),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}