import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../services/profile_service.dart';
import '../services/api_client.dart';
import '/models/user_profile.dart';
import '../../features/auth/presentation/search_screen.dart'; 

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Map / Discovery')),
    body: const Center(
      child: Text('Map/Discovery Content (Index 1)', style: TextStyle(fontSize: 24, color: Colors.blue)),
    ),
  );
}

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

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    body: const Center(
      child: Text('Messages Content (Index 2)', style: TextStyle(fontSize: 24, color: Colors.green)),
    ),
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
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Colors.transparent,
      ),
      child: Icon(
        icon,
        color: selected ? Color.fromARGB(255, 76, 89, 185) : Colors.white),
    );
  }
}

class PathwayNavShell extends StatefulWidget { 
  const PathwayNavShell({Key? key}) : super(key: key);

  @override
  _PathwayNavShellState createState() => _PathwayNavShellState();
}

class _PathwayNavShellState extends State<PathwayNavShell> {
  int _selectedIndex = 0; 

  final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const MapScreen(),        
    const SearchScreen(),
    const BadgesScreen(),      
    const MessagesScreen(),  
    const ProfilePage(),    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), 
      
      bottomNavigationBar: Container(
        // Add texture and color to the bottom navigation bar
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 76, 89, 185),
          image: DecorationImage(
            image: AssetImage('assets/images/navbar_texture.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Color.fromARGB(30, 0, 0, 0),
                BlendMode.dstIn,
            )
          ),
        ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Color.fromARGB(255, 76, 89, 185),
        currentIndex: _selectedIndex,

        selectedItemColor: Colors.white, 
        unselectedItemColor: Colors.white,

        selectedLabelStyle: const TextStyle(
          fontSize: 12
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12
        ),

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
            label: 'Home'
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
            label: 'Map'
          ),
          // Search icon
          BottomNavigationBarItem(
            icon: const SelectedNavIcon(
              icon: Icons.search_rounded,
              selected: false,
            ),
            activeIcon: const SelectedNavIcon(
              icon: Icons.search_rounded,
              selected: true,
            ),
            label: 'Search'
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
            label: 'Badges'
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
            label: 'Messages'
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
            label: 'Profile'
          ),
        ],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      )
    );
  }
}
