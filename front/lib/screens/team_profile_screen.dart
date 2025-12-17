import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_models.dart';
import '../models/game.dart';
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import 'game_hub_screen.dart';
import 'outcome_studio_screen.dart';
import 'player_insight_screen.dart'; // Додайте цей імпорт

/// Team Profile Screen - профіль команди з roster та schedule
class TeamProfileScreen extends StatefulWidget {
  final int teamId;
  final Team? team; // Опціонально передати team якщо вже є

  const TeamProfileScreen({
    super.key,
    required this.teamId,
    this.team,
  });

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();

  Team? _team;
  List<Player> _roster = [];
  List<TeamScheduleGame> _schedule = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _team = widget.team; // Використати передану team якщо є
    _loadTeamData();
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? teamInfoData;

      // 1. Завантажити team info, якщо ще немає
      if (_team == null) {
        print('Loading team info for team ${widget.teamId}');
        teamInfoData = await _apiService.getTeamInfo(widget.teamId);
        _team = Team.fromJson(teamInfoData);
        print('Team loaded: ${_team!.teamName}');
      }

      // 2. Завантажити roster
      print('Loading roster...');
      // Використовуємо teamAbbrev для оптимізації
      final rosterData = await _apiService.getTeamRoster(
          widget.teamId,
          teamAbbrev: _team?.teamAbbrev
      );

      // Використовуємо хелпер для парсингу
      final roster = _parseRosterData(rosterData);

      // 3. Завантажити schedule
      print('Loading schedule...');
      final scheduleData = await _apiService.getTeamSchedule(widget.teamId);

      // Використовуємо хелпер для парсингу
      final schedule = _parseScheduleData(scheduleData);

      setState(() {
        _roster = roster;
        _schedule = schedule;
        _isLoading = false;
      });

      print('✅ Loaded ${roster.length} players and ${schedule.length} games');

      // Зберігаємо у фоновому режимі, не чекаємо await
      _saveToCache(teamInfoData, rosterData, scheduleData);

    } catch (e) {
      print('❌ Error loading team data: $e');

      print('🔄 Attempting to load from cache...');
      final loadedFromCache = await _loadFromCache();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (loadedFromCache) {
            _isOffline = true; // Показуємо банер "Offline"
            print('✅ Data restored from cache');
          } else {
            _errorMessage = 'Failed to load team data. Check internet connection.';
          }
        });
      }
    }
  }

  /// Парсинг складу команди
  List<Player> _parseRosterData(Map<String, dynamic> rosterData) {
    final forwards = rosterData['forwards'] as List? ?? [];
    final defensemen = rosterData['defensemen'] as List? ?? [];
    final goalies = rosterData['goalies'] as List? ?? [];

    print('Roster found: ${forwards.length} F, ${defensemen.length} D, ${goalies.length} G');

    final roster = <Player>[];

    // Допоміжна функція для додавання
    void addPlayers(List list) {
      for (var json in list) {
        try {
          roster.add(Player.fromJson(json));
        } catch (e) {
          print('Error parsing player: $e');
        }
      }
    }

    addPlayers(forwards);
    addPlayers(defensemen);
    addPlayers(goalies);

    return roster;
  }

  /// Парсинг розкладу
  List<TeamScheduleGame> _parseScheduleData(Map<String, dynamic> scheduleData) {
    final games = scheduleData['games'] as List? ?? [];
    print('Schedule found: ${games.length} games');

    final schedule = <TeamScheduleGame>[];
    for (var json in games) {
      try {
        schedule.add(TeamScheduleGame.fromJson(json, widget.teamId));
      } catch (e) {
        print('Error parsing game: $e');
      }
    }
    return schedule;
  }

  /// Збереження даних у кеш (SharedPreferences)
  Future<void> _saveToCache(Map<String, dynamic>? teamInfo, Map<String, dynamic> roster, Map<String, dynamic> schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Кешуємо інфо про команду (якщо завантажували)
      if (teamInfo != null) {
        await prefs.setString('cache_team_info_${widget.teamId}', json.encode(teamInfo));
      }

      // Кешуємо сирі JSON дані
      await prefs.setString('cache_team_roster_${widget.teamId}', json.encode(roster));
      await prefs.setString('cache_team_schedule_${widget.teamId}', json.encode(schedule));

      print('💾 Team data cached successfully for ID ${widget.teamId}');
    } catch (e) {
      print('⚠️ Failed to save to cache: $e');
    }
  }

  /// Завантаження даних з кешу
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool hasData = false;

      // 1. Відновлюємо команду
      if (_team == null) {
        final teamJson = prefs.getString('cache_team_info_${widget.teamId}');
        if (teamJson != null) {
          final teamData = json.decode(teamJson);
          _team = Team.fromJson(teamData);
          hasData = true;
        }
      } else {
        hasData = true; // Команда вже є
      }

      // 2. Відновлюємо склад
      final rosterJson = prefs.getString('cache_team_roster_${widget.teamId}');
      if (rosterJson != null) {
        final rosterData = json.decode(rosterJson);
        _roster = _parseRosterData(rosterData);
        hasData = true;
      }

      // 3. Відновлюємо розклад
      final scheduleJson = prefs.getString('cache_team_schedule_${widget.teamId}');
      if (scheduleJson != null) {
        final scheduleData = json.decode(scheduleJson);
        _schedule = _parseScheduleData(scheduleData);
        hasData = true;
      }

      return hasData;
    } catch (e) {
      print('⚠️ Error loading from cache: $e');
      return false;
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoritesService.isFavoriteTeam(widget.teamId);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavoriteTeam(widget.teamId);
    await _checkFavorite();
  }

  void _predictNextMatchup() {
    if (_schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No upcoming games')),
      );
      return;
    }

    // Get next game from schedule
    final nextGame = _schedule.first;

    // Create a Game object from TeamScheduleGame
    final game = Game(
      gameId: nextGame.gameId,
      status: nextGame.gameState,
      statusText: nextGame.gameState,
      dateTime: nextGame.gameDate,
      homeTeamId: nextGame.isHomeGame ? widget.teamId : 0,
      homeTeamName: nextGame.isHomeGame ? (_team?.teamName ?? 'Home') : nextGame.opponentName,
      awayTeamId: nextGame.isHomeGame ? 0 : widget.teamId,
      awayTeamName: nextGame.isHomeGame ? nextGame.opponentName : (_team?.teamName ?? 'Away'),
    );

    // Navigate to Outcome Studio with prefilled game
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutcomeStudioScreen(prefilledGame: game),
      ),
    );
  }

  void _openPlayerInsight(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerInsightScreen(
          playerId: player.playerId,
          playerName: player.fullName,
        ),
      ),
    );
  }

  Future<void> _openGameHub(TeamScheduleGame scheduleGame) async {
    try {
      // Показуємо спіннер
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ),
              SizedBox(width: 16),
              Text('Loading game details...'),
            ],
          ),
          duration: const Duration(seconds: 1), // Трохи менша тривалість
        ),
      );

      // ВИПРАВЛЕННЯ: Завантажуємо гру напряму за ID.
      // Більше ніяких пошуків по датах та тижнях.
      final game = await _apiService.getGameById(scheduleGame.gameId);

      if (!mounted) return;

      // Прибираємо SnackBar перед переходом
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Переходимо на екран гри
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameHubScreen(game: game),
        ),
      );
    } catch (e) {
      print('❌ Error opening game hub: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load game details. Try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isOffline) _buildOfflineBanner(),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildTabContent(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF8ACEF2),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F265C)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_outline,
                  color: const Color(0xFF0F265C),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Team logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _team?.teamLogo != null
                ? Image.network(
              _team!.teamLogo!,
              errorBuilder: (_, __, ___) => _buildLogoFallback(),
            )
                : _buildLogoFallback(),
          ),

          const SizedBox(height: 16),

          // Team name
          Text(
            _team?.teamName ?? 'Loading...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Division • Conference
          Text(
            '${_team?.divisionName ?? ''} Division • ${_team?.conferenceName ?? ''} Conference',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoFallback() {
    return const Icon(
      Icons.sports_hockey,
      size: 50,
      color: Color(0xFF6B9EB8),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You are offline. Showing last saved data.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
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
          Tab(text: 'ROSTER'),
          Tab(text: 'SCHEDULE'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRosterTab(),
        _buildScheduleTab(),
      ],
    );
  }

  Widget _buildRosterTab() {
    if (_roster.isEmpty) {
      return _buildEmptyState('No roster data available');
    }

    // Розділити гравців по позиціям
    final forwards = _roster.where((p) =>
    p.position == 'C' || p.position == 'LW' || p.position == 'RW').toList();
    final defensemen = _roster.where((p) => p.position == 'D').toList();
    final goalies = _roster.where((p) => p.position == 'G').toList();

    // Сортувати по номерах
    forwards.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
    defensemen.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
    goalies.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      color: const Color(0xFF0F265C),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRosterTable(forwards, 'Forwards'),
          const SizedBox(height: 16),
          _buildRosterTable(defensemen, 'Defensemen'),
          const SizedBox(height: 16),
          _buildRosterTable(goalies, 'Goalies'),
        ],
      ),
    );
  }

  Widget _buildRosterTable(List<Player> players, String title) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE8F4F8)),

          // Header
          _buildRosterHeader(players.first.isGoalie),

          const Divider(height: 1, color: Color(0xFFE8F4F8)),

          // Players
          ...players.map((player) => _buildPlayerRow(player)),
        ],
      ),
    );
  }

  Widget _buildRosterHeader(bool isGoalie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _buildHeaderCell('#', width: 35),
          _buildHeaderCell('Player', flex: 3),
          _buildHeaderCell('Pos', width: 40),
          _buildHeaderCell('Shoots', width: 50),
          if (!isGoalie) ...[
            _buildHeaderCell('GP', width: 35),
            _buildHeaderCell('G', width: 30),
            _buildHeaderCell('A', width: 30),
            _buildHeaderCell('P', width: 35),
          ] else ...[
            _buildHeaderCell('GP', width: 35),
            _buildHeaderCell('W', width: 30),
            _buildHeaderCell('L', width: 30),
            _buildHeaderCell('SV%', width: 50),
          ],
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

  Widget _buildPlayerRow(Player player) {
    return InkWell(
      onTap: () => _openPlayerInsight(player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE8F4F8).withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // Jersey number
            SizedBox(
              width: 35,
              child: Text(
                player.jerseyNumber.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Player name
            Expanded(
              flex: 3,
              child: Text(
                player.lastName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
            ),

            // Position
            SizedBox(
              width: 40,
              child: Text(
                player.position,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Shoots
            SizedBox(
              width: 50,
              child: Text(
                player.shoots ?? '-',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Stats
            if (!player.isGoalie) ...[
              _buildStatCell(player.gamesPlayed.toString(), width: 35),
              _buildStatCell(player.goals.toString(), width: 30),
              _buildStatCell(player.assists.toString(), width: 30),
              _buildStatCell(player.points.toString(), width: 35, bold: true),
            ] else ...[
              _buildStatCell(player.gamesPlayed.toString(), width: 35),
              _buildStatCell(player.wins?.toString() ?? '-', width: 30),
              _buildStatCell(player.losses?.toString() ?? '-', width: 30),
              _buildStatCell(
                player.savePercentage != null
                    ? player.savePercentage!.toStringAsFixed(3)
                    : '-',
                width: 50,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, {double? width, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: const Color(0xFF0F265C),
          fontFamily: 'Lato',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_schedule.isEmpty) {
      return _buildEmptyState('No upcoming games');
    }

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      color: const Color(0xFF0F265C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _schedule.length,
        itemBuilder: (context, index) {
          return _buildScheduleItem(_schedule[index]);
        },
      ),
    );
  }

  Widget _buildScheduleItem(TeamScheduleGame game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F4F8)),
      ),
      child: InkWell(
        onTap: () => _openGameHub(game),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              game.dateDisplay,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B9EB8),
                fontFamily: 'Lato',
              ),
            ),

            const SizedBox(height: 8),

            // Opponent
            Row(
              children: [
                Text(
                  game.isHomeGame ? 'vs' : '@',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.opponentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F265C),
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time and Venue
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Color(0xFF6B9EB8)),
                const SizedBox(width: 4),
                Text(
                  game.timeDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 14, color: Color(0xFF6B9EB8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    game.venue ?? 'TBD',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B9EB8),
                      fontFamily: 'Lato',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Follow team button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleFavorite,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFavorite
                    ? const Color(0xFF0F265C)
                    : Colors.white,
                foregroundColor: _isFavorite
                    ? Colors.white
                    : const Color(0xFF0F265C),
                side: BorderSide(
                  color: const Color(0xFF0F265C),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(_isFavorite ? Icons.star : Icons.star_outline),
              label: Text(
                _isFavorite ? 'Following' : 'Follow team',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Predict next matchup button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _predictNextMatchup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.track_changes),
              label: const Text(
                'Predict next matchup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
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
              onPressed: _loadTeamData,
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