import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '/features/auth/presentation/map_screen.dart';

import 'package:pathway/core/utils/accessibility_controller.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Badges')),
    body: const Center(
      child: Text('Badges Content', style: TextStyle(fontSize: 24, color: Colors.deepPurple)),
      )
  );
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
    // Pull color scheme from Theme
    final cs = Theme.of(context).colorScheme;

    final bg = selected ? cs.onPrimary : Colors.transparent;
    final fg = selected ? cs.primary : cs.onPrimary;
    
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Set decoration color to bg color from Theme
        color: bg,
      ),
      child: Icon(
        icon,
        // Set icon color to fg color from Theme
        color: fg
      )
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
        data: Theme.of(context).copyWith(
          navigationBarTheme: Theme.of(context).navigationBarTheme,
        ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedIndex,

        selectedItemColor: navFg, 
        unselectedItemColor: navFg,

        selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: navFg,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: navFg,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
          // Home icon
            icon: SelectedNavIcon(
              icon: Icons.home_rounded,
              selected: false,
              ), 
            activeIcon: SelectedNavIcon(
              icon: Icons.home_rounded,
              selected: true,
              ),
            label: 'Home'
          ),
          // Map icon
          BottomNavigationBarItem(
            icon: SelectedNavIcon(
              icon: Icons.map_rounded,
              selected: false,
            ),
            activeIcon: SelectedNavIcon(
              icon: Icons.map_rounded,
              selected: true,
            ),
            label: 'Map'
          ),
          // Badges icon
          BottomNavigationBarItem(
            icon: SelectedNavIcon(
              icon: Icons.star_rounded,
              selected: false,
            ),
            activeIcon: SelectedNavIcon(
              icon: Icons.star_rounded,
              selected: true,
            ),
            label: 'Badges'
          ),
          // Message icon
          BottomNavigationBarItem(
            icon: SelectedNavIcon(
              icon: Icons.message,
              selected: false,
            ),
            activeIcon: SelectedNavIcon(
              icon: Icons.message,
              selected: true,
            ),
            label: 'Messages'
          ),

          BottomNavigationBarItem(
            icon: SelectedNavIcon(
              icon: Icons.person_rounded,
              selected: false,
            ),
            activeIcon: SelectedNavIcon(
              icon: Icons.person_rounded,
              selected: true,
            ),
            label: 'Profile'
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
