import 'package:flutter/material.dart';
import '../models/team_standing.dart';
import '../models/team_models.dart'; // ДОДАНО
import '../services/nhl_api_service.dart';
import 'team_profile_screen.dart'; // ДОДАНО

/// Standings Screen - турнірні таблиці NHL
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

  Future<void> _loadStandings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final standings = await _apiService.getStandings();

      setState(() {
        _allStandings = standings;
        _isLoading = false;
      });

      print('Loaded ${standings.length} teams');
    } catch (e) {
      print('Error loading standings: $e');
      setState(() {
        _errorMessage = 'Failed to load standings';
        _isLoading = false;
      });
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
        title: const Text(
          'League Tables',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F265C),
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadStandings,
            icon: const Icon(Icons.refresh, color: Color(0xFF0F265C)),
            tooltip: 'Refresh',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildWildCardTab(),
          _buildDivisionTab(),
          _buildLeagueTab(),
        ],
      ),
    );
  }

  Widget _buildWildCardTab() {
    // Розділити по конференціям
    final easternTeams = _allStandings
        .where((t) => t.conferenceName.toLowerCase().contains('eastern'))
        .toList();
    final westernTeams = _allStandings
        .where((t) => t.conferenceName.toLowerCase().contains('western'))
        .toList();

    // Сортувати по points, потім ROW, потім goal diff
    easternTeams.sort(_compareTeams);
    westernTeams.sort(_compareTeams);

    return RefreshIndicator(
      onRefresh: _loadStandings,
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
    // Групувати по дивізіонам
    final divisions = <String, List<TeamStanding>>{};
    for (var team in _allStandings) {
      divisions.putIfAbsent(team.divisionName, () => []).add(team);
    }

    // Сортувати команди в кожному дивізіоні
    for (var teams in divisions.values) {
      teams.sort(_compareTeams);
    }

    // Порядок дивізіонів: Atlantic, Metropolitan, Central, Pacific
    final divisionOrder = ['Atlantic', 'Metropolitan', 'Central', 'Pacific'];
    final sortedDivisions = divisionOrder
        .where((name) => divisions.containsKey(name))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadStandings,
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
    // Сортувати всі команди
    final sortedTeams = List<TeamStanding>.from(_allStandings);
    sortedTeams.sort(_compareTeams);

    return RefreshIndicator(
      onRefresh: _loadStandings,
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
          // Header
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE8F4F8)),

          // Rows
          ...teams.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final position = index + 1;

            // Визначити статус для wild card
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
        // DEBUG: Перевірити що передається
        print('=== TEAM TAP DEBUG ===');
        print('Team ID: ${team.teamId}');
        print('Team Name: ${team.teamName}');
        print('Team Abbrev: ${team.teamAbbrev}');
        print('Team Logo: ${team.teamLogo}');
        print('Division: ${team.divisionName}');
        print('Conference: ${team.conferenceName}');
        print('====================');

        // Перевірка перед навігацією
        if (team.teamId == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Team ID is 0. Cannot open profile.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        // Навігація до Team Profile
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
            // Position with indicator
            SizedBox(
              width: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicator
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
                  // Position number
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

            // Team name
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

            // Stats
            _buildStatCell(team.gamesPlayed.toString(), width: 35),
            _buildStatCell(team.wins.toString(), width: 30),
            _buildStatCell(team.losses.toString(), width: 30),
            _buildStatCell(team.overtimeLosses.toString(), width: 35),
            _buildStatCell(
              team.points.toString(),
              width: 40,
              bold: true,
            ),
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
    // 1. По points (більше краще)
    if (a.points != b.points) {
      return b.points.compareTo(a.points);
    }

    // 2. По ROW (більше краще)
    if (a.regulationWins != b.regulationWins) {
      return b.regulationWins.compareTo(a.regulationWins);
    }

    // 3. По goal differential (більше краще)
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
              onPressed: _loadStandings,
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