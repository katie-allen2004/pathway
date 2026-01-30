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
      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), 
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Badges'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
