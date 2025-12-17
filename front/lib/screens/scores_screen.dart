import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../models/favorites_store.dart';
import '../services/nhl_api_service.dart'; // СПРАВЖНІЙ API
import '../services/favorites_service.dart';
import '../services/preferences_service.dart';
import '../widgets/custom_date_picker.dart'; // Кастомний date picker
import 'game_hub_screen.dart'; // Game Hub

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService(); // СПРАВЖНІЙ API
  final FavoritesService _favoritesService = FavoritesService();
  final PreferencesService _preferencesService = PreferencesService();

  DateTime _selectedDate = DateTime.now();
  List<Game> _allGames = [];
  FavoritesStore _favorites = const FavoritesStore();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Нормалізувати дату (без часу)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    _initialize();
  }

  Future<void> _initialize() async {
    // Завантажити налаштування та визначити початкову дату
    final prefs = await _preferencesService.loadPreferences();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedDate = _getDateFromPreference(prefs.defaultGameDay);
      // Якщо дата в майбутньому, використати сьогодні
      if (_selectedDate.isAfter(today)) {
        _selectedDate = today;
      }
    });

    // Завантажити favorites
    await _loadFavorites();

    // Завантажити ігри
    await _loadGames();
  }

  DateTime _getDateFromPreference(String defaultDay) {
    final now = DateTime.now();
    switch (defaultDay) {
      case 'lastnight':
        return DateTime(now.year, now.month, now.day - 1);
      case 'tomorrow':
        return DateTime(now.year, now.month, now.day + 1);
      default: // 'today'
        return DateTime(now.year, now.month, now.day);
    }
  }

  // ДОДАНО: Окремий метод для завантаження favorites
  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.loadFavorites();
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Формат для NHL Stats API: 2024-12-16
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      print('Loading games for date: $dateStr');

      final games = await _apiService.getScheduleByDate(dateStr);

      setState(() {
        _allGames = games;
        _isLoading = false;
      });

      // Debug
      _debugGameStatuses();
    } catch (e) {
      print('Error loading games: $e');
      setState(() {
        _errorMessage = 'Failed to load games: $e';
        _isLoading = false;
      });
    }
  }

  List<Game> get _liveGames =>
      _allGames.where((game) => game.isLive).toList();

  List<Game> get _upcomingGames =>
      _allGames.where((game) => game.isUpcoming).toList();

  List<Game> get _finalGames =>
      _allGames.where((game) => game.isFinal).toList();

  // Debug - показати статуси всіх ігор
  void _debugGameStatuses() {
    print('=== GAME STATUSES DEBUG ===');
    print('Current DateTime: ${DateTime.now()}');
    print('Selected Date: $_selectedDate');
    print('Total games: ${_allGames.length}');
    print('Live: ${_liveGames.length}');
    print('Upcoming: ${_upcomingGames.length}');
    print('Final: ${_finalGames.length}');
    print('---');

    for (var game in _allGames.take(3)) {
      print('Game ${game.gameId}:');
      print('  status="${game.status}"');
      print('  gameTime=${game.dateTime}');
      print('  isLive=${game.isLive}, isUpcoming=${game.isUpcoming}, isFinal=${game.isFinal}');
      print('  ${game.awayTeamName} @ ${game.homeTeamName}');
    }
    print('=========================');
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadGames();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadGames();
  }

  Future<void> _selectDate() async {
    final picked = await CustomDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadGames();
    }
  }

  Future<void> _toggleFavorite(int gameId) async {
    await _favoritesService.toggleFavoriteGame(gameId);
    await _loadFavorites(); // ВИПРАВЛЕНО: Використовуємо окремий метод
  }

  Future<void> _toggleAlerts(int gameId) async {
    await _favoritesService.toggleAlertsForGame(gameId);
    await _loadFavorites(); // ВИПРАВЛЕНО: Використовуємо окремий метод
  }

  void _openOutcomeStudio(Game game) {
    // TODO: Navigate to Outcome Studio with pre-filled teams
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening Outcome Studio for ${game.awayTeamName} @ ${game.homeTeamName}'),
      ),
    );
  }

  // ВИПРАВЛЕНО: Тепер метод async і обробляє результат з GameHubScreen
  Future<void> _openGameCenter(Game game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GameHubScreen(game: game),
      ),
    );

    // Якщо favorites змінились (result == true), перезавантажуємо їх
    if (result == true) {
      print('Favorites changed in GameHub, reloading...');
      await _loadFavorites();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Білий фон
      body: SafeArea(
        child: Column(
          children: [
            // Header з кольором #8ACEF2
            Container(
              color: const Color(0xFF8ACEF2),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDateNavigation(),
                  _buildTabs(),
                ],
              ),
            ),

            // Games List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildGamesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Outcome Studio
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Outcome Studio...')),
          );
        },
        backgroundColor: const Color(0xFFFFA500),
        icon: const Icon(Icons.track_changes, color: Colors.white),
        label: const Text(
          'Outcome Studio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RinkSync Coach',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'NHL Matchboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F265C),
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to Settings
            },
            icon: const Icon(Icons.settings, color: Color(0xFF0F265C)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    final dateFormat = DateFormat('EEE, MMM d'); // Wed, Dec 12 (коротше)
    final dateStr = dateFormat.format(_selectedDate).toUpperCase();
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left arrow
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left, color: Color(0xFF0F265C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
            iconSize: 24,
          ),

          // Date display (flexible)
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F265C),
                          fontFamily: 'Lato',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF0F265C),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Today button (if not today)
          if (!isToday)
            Container(
              margin: const EdgeInsets.only(left: 4),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  _loadGames();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),

          // Right arrow
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right, color: Color(0xFF0F265C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
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
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'LIVE'),
          Tab(text: 'UPCOMING'),
          Tab(text: 'FINAL'),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGamesTab(_liveGames, 'live'),
        _buildGamesTab(_upcomingGames, 'upcoming'),
        _buildGamesTab(_finalGames, 'final'),
      ],
    );
  }

  Widget _buildGamesTab(List<Game> games, String tabType) {
    if (games.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadGames();
        await _loadFavorites(); // ДОДАНО: Також оновлюємо favorites при pull-to-refresh
      },
      color: const Color(0xFF0F265C),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          return _buildGameTile(games[index], tabType);
        },
      ),
    );
  }

  Widget _buildGameTile(Game game, String tabType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openGameCenter(game),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Time info (for live games)
            if (tabType == 'live' && game.liveTimeDisplay.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      game.liveTimeDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF0000),
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      game.periodText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B9EB8),
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),

            // Teams and scores
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Away team
                      _buildTeamRow(
                        game.awayTeamName,
                        game.awayTeamScore,
                        tabType == 'final' && game.winner == 'away',
                      ),
                      const SizedBox(height: 8),
                      // Home team
                      _buildTeamRow(
                        game.homeTeamName,
                        game.homeTeamScore,
                        tabType == 'final' && game.winner == 'home',
                      ),
                    ],
                  ),
                ),

                // Icons
                Column(
                  children: [
                    Row(
                      children: [
                        // Favorite
                        IconButton(
                          onPressed: () => _toggleFavorite(game.gameId),
                          icon: Icon(
                            _favorites.isFavoriteGame(game.gameId)
                                ? Icons.star
                                : Icons.star_outline,
                            color: _favorites.isFavoriteGame(game.gameId)
                                ? const Color(0xFF0F265C)
                                : const Color(0xFF6B9EB8),
                          ),
                        ),
                        // Alerts
                        IconButton(
                          onPressed: () => _toggleAlerts(game.gameId),
                          icon: Icon(
                            _favorites.hasAlertsForGame(game.gameId)
                                ? Icons.notifications
                                : Icons.notifications_outlined,
                            color: _favorites.hasAlertsForGame(game.gameId)
                                ? const Color(0xFFFFA500)
                                : const Color(0xFF6B9EB8),
                          ),
                        ),
                      ],
                    ),
                    // Predict
                    IconButton(
                      onPressed: () => _openOutcomeStudio(game),
                      icon: const Icon(
                        Icons.track_changes,
                        color: Color(0xFFFFA500),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Upcoming time or Final status
            if (tabType == 'upcoming')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  game.upcomingTimeDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B9EB8),
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            if (tabType == 'final')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Final',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F265C),
                    fontFamily: 'Lato',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(String teamName, int? score, bool isWinner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF0F265C),
              fontFamily: 'Lato',
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isWinner
                  ? const Color(0xFF0F265C)
                  : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isWinner ? Colors.white : const Color(0xFF0F265C),
                fontFamily: 'Lato',
              ),
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
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No NHL games for this date.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try another day.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B9EB8),
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: _loadGames,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F265C),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}