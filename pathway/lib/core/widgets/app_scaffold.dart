import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '/features/auth/presentation/map_screen.dart';

import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:pathway/features/profile/presentation/widgets/badges_section.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F7),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(color: Color(0xFF4F67D6)),
            child: const Text(
              'Badges',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 620),
                  child: BadgesSection(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const SelectedNavIcon({
    super.key,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = selected ? cs.onPrimary : Colors.transparent;
    final fg = selected ? cs.primary : cs.onPrimary;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Icon(icon, color: fg),
    );
  }
}

class PathwayNavShell extends StatefulWidget {
  const PathwayNavShell({super.key});

  @override
  State<PathwayNavShell> createState() => _PathwayNavShellState();
}

class _PathwayNavShellState extends State<PathwayNavShell> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const MapScreen(),
    const BadgesScreen(),
    const ConversationsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pull color scheme from theme & watch AccessibilityController for theme changes
    final cs = Theme.of(context).colorScheme;
    final a11y = context.watch<AccessibilityController>();
    final highContrast = a11y.settings.highContrast;

    // If highContrast == true, navBg = Black. Otherwise, it is onPrimary
    final navBg = highContrast ? Colors.black : cs.primary;
    // If highContrast == true, navFg = White. Otherwise, it is onPrimary
    final navFg = highContrast ? Colors.white : cs.onPrimary;

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: Container(
        // Add texture and color to the bottom navigation bar
        decoration: BoxDecoration(
          color: navBg,
          image: highContrast
              ? null // If highContrast, no bg texture
              : const DecorationImage(
                  image: AssetImage('assets/images/navbar_texture.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color.fromARGB(30, 0, 0, 0),
                    BlendMode.dstIn,
                  ),
                ),
        ),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(navigationBarTheme: Theme.of(context).navigationBarTheme),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,

            selectedItemColor: navFg,
            unselectedItemColor: navFg,

            selectedLabelStyle: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 12, color: navFg),
            unselectedLabelStyle: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 12, color: navFg),
            showSelectedLabels: true,
            showUnselectedLabels: true,

            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                // Home icon
                icon: const SelectedNavIcon(
                  icon: Icons.home_rounded,
                  selected: false,
                ),
                activeIcon: const SelectedNavIcon(
                  icon: Icons.home_rounded,
                  selected: true,
                ),
                label: 'Home',
              ),
              // Map icon
              BottomNavigationBarItem(
                icon: const SelectedNavIcon(
                  icon: Icons.map_rounded,
                  selected: false,
                ),
                activeIcon: const SelectedNavIcon(
                  icon: Icons.map_rounded,
                  selected: true,
                ),
                label: 'Map',
              ),
              // Badges icon
              BottomNavigationBarItem(
                icon: const SelectedNavIcon(
                  icon: Icons.star_rounded,
                  selected: false,
                ),
                activeIcon: const SelectedNavIcon(
                  icon: Icons.star_rounded,
                  selected: true,
                ),
                label: 'Badges',
              ),
              // Message icon
              BottomNavigationBarItem(
                icon: const SelectedNavIcon(
                  icon: Icons.message,
                  selected: false,
                ),
                activeIcon: const SelectedNavIcon(
                  icon: Icons.message,
                  selected: true,
                ),
                label: 'Messages',
              ),

              BottomNavigationBarItem(
                icon: const SelectedNavIcon(
                  icon: Icons.person_rounded,
                  selected: false,
                ),
                activeIcon: const SelectedNavIcon(
                  icon: Icons.person_rounded,
                  selected: true,
                ),
                label: 'Profile',
              ),
            ],
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
