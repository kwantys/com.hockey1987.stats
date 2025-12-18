import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stats1/screens/settings_screen.dart';
import '../models/game.dart';
import '../models/favorites_store.dart';
import '../models/user_preferences.dart'; // ДОДАНО
import '../services/nhl_api_service.dart';
import '../services/favorites_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart'; // ДОДАНО
import '../shared/services/logger.dart'; // ДОДАНО
import '../widgets/custom_date_picker.dart';
import '../widgets/error_display.dart';
import 'game_hub_screen.dart';
import 'outcome_studio_screen.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NHLApiService _apiService = NHLApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final PreferencesService _preferencesService = PreferencesService();

  DateTime _selectedDate = DateTime.now();
  List<Game> _allGames = [];
  FavoritesStore _favorites = const FavoritesStore();
  UserPreferences _userPrefs = const UserPreferences(); // ДОДАНО
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await _preferencesService.loadPreferences();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _userPrefs = prefs; // ЗБЕРІГАЄМО ПРЕФИ
      _selectedDate = _getDateFromPreference(prefs.defaultGameDay);
      if (_selectedDate.isAfter(today)) {
        _selectedDate = today;
      }
    });

    await _loadFavorites();
    await _loadGames();
  }

  DateTime _getDateFromPreference(String defaultDay) {
    final now = DateTime.now();
    switch (defaultDay) {
      case 'lastnight':
        return DateTime(now.year, now.month, now.day - 1);
      case 'tomorrow':
        return DateTime(now.year, now.month, now.day + 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

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
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      AppLogger.d('Loading games for date: $dateStr'); // Використовуємо AppLogger

      final games = await _apiService.getScheduleByDate(dateStr);

      setState(() {
        _allGames = games;
        _isLoading = false;
      });

      _debugGameStatuses();
    } catch (e) {
      AppLogger.e('Error loading games: $e'); // Використовуємо AppLogger
      setState(() {
        _errorMessage = e.toString();
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

  void _debugGameStatuses() {
    AppLogger.d('=== GAME STATUSES DEBUG ===');
    AppLogger.d('Current DateTime: ${DateTime.now()}');
    AppLogger.d('Selected Date: $_selectedDate');
    AppLogger.d('Total games: ${_allGames.length}');
    AppLogger.d('Live: ${_liveGames.length}');
    AppLogger.d('Upcoming: ${_upcomingGames.length}');
    AppLogger.d('Final: ${_finalGames.length}');
    AppLogger.d('---');

    for (var game in _allGames.take(3)) {
      AppLogger.d('Game ${game.gameId}: status="${game.status}", isLive=${game.isLive}, isUpcoming=${game.isUpcoming}, isFinal=${game.isFinal}');
    }
    AppLogger.d('=========================');
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
    await _loadFavorites();
  }

  // МОДИФІКОВАНО: Інтеграція сповіщень
  Future<void> _toggleAlerts(Game game) async {
    await _favoritesService.toggleAlertsForGame(game.gameId);
    final isEnabled = !_favorites.hasAlertsForGame(game.gameId); // Стан після перемикання

    if (isEnabled) {
      AppLogger.i('Enabling alerts for game: ${game.gameId}');

      // Плануємо сповіщення про початок матчу
      await NotificationService.scheduleMatchAlert(
        gameId: game.gameId,
        teamNames: '${game.awayTeamName} @ ${game.homeTeamName}',
        startTime: game.dateTime,
      );

      // Плануємо сповіщення про завершення, якщо увімкнено в префах
      if (_userPrefs.finalScoreAlerts) {
        await NotificationService.scheduleMatchAlert(
          gameId: game.gameId + 1000000,
          teamNames: 'Final Result: ${game.awayTeamName} vs ${game.homeTeamName}',
          startTime: game.dateTime.add(const Duration(hours: 3)),
        );
      }
    } else {
      AppLogger.d('Disabling alerts for game: ${game.gameId}');
      await NotificationService.cancelMatchAlert(game.gameId);
      // Логіка скасування в NotificationService
    }

    await _loadFavorites();
  }

  void _openOutcomeStudio(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutcomeStudioScreen(prefilledGame: game),
      ),
    );
  }

  Future<void> _openGameCenter(Game game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GameHubScreen(game: game),
      ),
    );

    if (result == true) {
      AppLogger.d('Favorites changed in GameHub, reloading...');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutcomeStudioScreen(),
            ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings, color: Color(0xFF0F265C)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    final dateFormat = DateFormat('EEE, MMM d');
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
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left, color: Color(0xFF0F265C)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
            iconSize: 24,
          ),
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
        await _loadFavorites();
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTeamRow(
                        game.awayTeamName,
                        game.awayTeamScore,
                        tabType == 'final' && game.winner == 'away',
                      ),
                      const SizedBox(height: 8),
                      _buildTeamRow(
                        game.homeTeamName,
                        game.homeTeamScore,
                        tabType == 'final' && game.winner == 'home',
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
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
                        IconButton(
                          onPressed: () => _toggleAlerts(game), // ВИКЛИКАЄМО МОДИФІКОВАНИЙ МЕТОД
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
    final String cleanMessage = _errorMessage?.replaceAll('Exception: ', '') ?? 'An error occurred';

    if (cleanMessage.contains("No internet")) {
      return ErrorDisplay(
        message: "No internet connection available. Please try again later.",
        onRetry: _loadGames,
      );
    }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              cleanMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
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