import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../services/profile_service.dart';
import '../services/api_client.dart';
import '/models/user_profile.dart';
// 1. Ensure this import points to your new file
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: const Center(
      child: Text('Profile Content (Index 3)', style: TextStyle(fontSize: 24, color: Colors.amber)),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('System Settings')),
    body: const Center(
      child: Text('System Settings Content (Index 4)', style: TextStyle(fontSize: 24, color: Colors.grey)),
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
    const MessagesScreen(),  
    const ProfileScreen(),   
    const SettingsScreen(),  
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
          // 2. Updated the Icon to Search
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
