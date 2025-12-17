import 'dart:convert';

/// Модель для збереження улюблених ігор, команд, гравців та налаштувань сповіщень
class FavoritesStore {
  final List<int> favoriteGames;   // GameID улюблених ігор
  final List<int> gamesWithAlerts; // GameID ігор з увімкненими сповіщеннями
  final List<int> favoriteTeams;   // TeamID улюблених команд
  final List<int> favoritePlayers; // ДОДАНО: PlayerID улюблених гравців

  const FavoritesStore({
    this.favoriteGames = const [],
    this.gamesWithAlerts = const [],
    this.favoriteTeams = const [],
    this.favoritePlayers = const [], // ДОДАНО
  });

  /// Створити копію з новими значеннями
  FavoritesStore copyWith({
    List<int>? favoriteGames,
    List<int>? gamesWithAlerts,
    List<int>? favoriteTeams,
    List<int>? favoritePlayers, // ДОДАНО
  }) {
    return FavoritesStore(
      favoriteGames: favoriteGames ?? this.favoriteGames,
      gamesWithAlerts: gamesWithAlerts ?? this.gamesWithAlerts,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      favoritePlayers: favoritePlayers ?? this.favoritePlayers, // ДОДАНО
    );
  }

  // ========== МЕТОДИ ДЛЯ ІГОР ==========

  /// Додати гру до улюблених
  FavoritesStore addFavoriteGame(int gameId) {
    if (favoriteGames.contains(gameId)) {
      return this;
    }
    return copyWith(
      favoriteGames: [...favoriteGames, gameId],
    );
  }

  /// Видалити гру з улюблених
  FavoritesStore removeFavoriteGame(int gameId) {
    return copyWith(
      favoriteGames: favoriteGames.where((id) => id != gameId).toList(),
    );
  }

  /// Перемкнути статус улюбленої гри
  FavoritesStore toggleFavoriteGame(int gameId) {
    if (favoriteGames.contains(gameId)) {
      return removeFavoriteGame(gameId);
    } else {
      return addFavoriteGame(gameId);
    }
  }

  /// Увімкнути сповіщення для гри
  FavoritesStore enableAlertsForGame(int gameId) {
    if (gamesWithAlerts.contains(gameId)) {
      return this;
    }
    return copyWith(
      gamesWithAlerts: [...gamesWithAlerts, gameId],
    );
  }

  /// Вимкнути сповіщення для гри
  FavoritesStore disableAlertsForGame(int gameId) {
    return copyWith(
      gamesWithAlerts: gamesWithAlerts.where((id) => id != gameId).toList(),
    );
  }

  /// Перемкнути сповіщення для гри
  FavoritesStore toggleAlertsForGame(int gameId) {
    if (gamesWithAlerts.contains(gameId)) {
      return disableAlertsForGame(gameId);
    } else {
      return enableAlertsForGame(gameId);
    }
  }

  /// Чи гра в улюблених
  bool isFavoriteGame(int gameId) => favoriteGames.contains(gameId);

  /// Чи увімкнені сповіщення для гри
  bool hasAlertsForGame(int gameId) => gamesWithAlerts.contains(gameId);

  // ========== МЕТОДИ ДЛЯ КОМАНД ==========

  /// Додати команду до улюблених
  FavoritesStore addFavoriteTeam(int teamId) {
    if (favoriteTeams.contains(teamId)) {
      return this;
    }
    return copyWith(
      favoriteTeams: [...favoriteTeams, teamId],
    );
  }

  /// Видалити команду з улюблених
  FavoritesStore removeFavoriteTeam(int teamId) {
    return copyWith(
      favoriteTeams: favoriteTeams.where((id) => id != teamId).toList(),
    );
  }

  /// Перемкнути статус улюбленої команди
  FavoritesStore toggleFavoriteTeam(int teamId) {
    if (favoriteTeams.contains(teamId)) {
      return removeFavoriteTeam(teamId);
    } else {
      return addFavoriteTeam(teamId);
    }
  }

  /// Чи команда в улюблених
  bool isFavoriteTeam(int teamId) => favoriteTeams.contains(teamId);

  // ========== МЕТОДИ ДЛЯ ГРАВЦІВ (НОВЕ) ==========

  /// Додати гравця до улюблених
  FavoritesStore addFavoritePlayer(int playerId) {
    if (favoritePlayers.contains(playerId)) {
      return this;
    }
    return copyWith(
      favoritePlayers: [...favoritePlayers, playerId],
    );
  }

  /// Видалити гравця з улюблених
  FavoritesStore removeFavoritePlayer(int playerId) {
    return copyWith(
      favoritePlayers: favoritePlayers.where((id) => id != playerId).toList(),
    );
  }

  /// Перемкнути статус улюбленого гравця
  FavoritesStore toggleFavoritePlayer(int playerId) {
    if (favoritePlayers.contains(playerId)) {
      return removeFavoritePlayer(playerId);
    } else {
      return addFavoritePlayer(playerId);
    }
  }

  /// Чи гравець в улюблених
  bool isFavoritePlayer(int playerId) => favoritePlayers.contains(playerId);

  // ========== JSON SERIALIZATION ==========

  /// Конвертувати в JSON
  Map<String, dynamic> toJson() {
    return {
      'favoriteGames': favoriteGames,
      'gamesWithAlerts': gamesWithAlerts,
      'favoriteTeams': favoriteTeams,
      'favoritePlayers': favoritePlayers, // ДОДАНО
    };
  }

  /// Створити з JSON
  factory FavoritesStore.fromJson(Map<String, dynamic> json) {
    return FavoritesStore(
      favoriteGames: (json['favoriteGames'] as List?)
          ?.map((e) => e as int)
          .toList() ??
          [],
      gamesWithAlerts: (json['gamesWithAlerts'] as List?)
          ?.map((e) => e as int)
          .toList() ??
          [],
      favoriteTeams: (json['favoriteTeams'] as List?)
          ?.map((e) => e as int)
          .toList() ??
          [],
      favoritePlayers: (json['favoritePlayers'] as List?) // ДОДАНО
          ?.map((e) => e as int)
          .toList() ??
          [],
    );
  }

  /// Конвертувати в String для збереження
  String toJsonString() => jsonEncode(toJson());

  /// Створити з String
  factory FavoritesStore.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FavoritesStore.fromJson(json);
  }

  @override
  String toString() {
    return 'FavoritesStore(games: ${favoriteGames.length}, '
        'alerts: ${gamesWithAlerts.length}, '
        'teams: ${favoriteTeams.length}, '
        'players: ${favoritePlayers.length})'; // ДОДАНО
  }
}