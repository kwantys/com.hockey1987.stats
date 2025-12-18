import 'package:flutter/material.dart';
import 'package:stats1/screens/insight_lab_screen.dart';
import '../screens/scores_screen.dart';
import '../screens/standings_screen.dart';
import '../screens/my_rink_screen.dart';
import '../screens/teams_screen.dart';

/// Головний навігаційний екран з Bottom Navigation Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Список екранів для кожної вкладки
  final List<Widget> _screens = [
    const ScoresScreen(),
    const StandingsScreen(),
    const TeamsScreen(),
    const InsightLabScreen(),
    const MyRinkScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFBFE3F6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: 'assets/images/nav_scores.webp',
                  label: 'Scores',
                ),
                _buildNavItem(
                  index: 1,
                  icon: 'assets/images/nav_standings.webp',
                  label: 'Standings',
                ),
                _buildNavItem(
                  index: 2,
                  icon: 'assets/images/nav_teams.webp',
                  label: 'Teams',
                ),
                _buildNavItem(
                  index: 3,
                  icon: 'assets/images/nav_insight.webp',
                  label: 'Insight',
                ),
                _buildNavItem(
                  index: 4,
                  icon: 'assets/images/nav_favorites.webp',
                  label: 'Favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Іконка
              Image.asset(
                icon,
                width: 28,
                height: 28,
                color: isSelected ? const Color(0xFF0F265C) : const Color(0xFF6B9EB8),
                errorBuilder: (context, error, stackTrace) {
                  // Fallback іконки якщо зображення не завантажилось
                  return Icon(
                    _getIconData(index),
                    size: 28,
                    color: isSelected ? const Color(0xFF0F265C) : const Color(0xFF6B9EB8),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Текст
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F265C) : const Color(0xFF6B9EB8),
                  fontFamily: 'Lato',
                ),
              ),
              // Індикатор вибраної вкладки
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F265C),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback іконки
  IconData _getIconData(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_today;
      case 1:
        return Icons.shield_outlined;
      case 2:
        return Icons.groups_outlined;
      case 3:
        return Icons.mail_outline;
      case 4:
        return Icons.star_outline;
      default:
        return Icons.home;
    }
  }
}

