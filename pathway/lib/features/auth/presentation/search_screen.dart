import 'package:flutter/material.dart';
// Note: Imports for later Azure integration
import '/core/services/profile_service.dart';
import '/core/services/api_client.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Services for future Azure connection
  final ApiClient _apiClient = ApiClient();
  late final ProfileService _profileService = ProfileService(apiClient: _apiClient);

  bool _isLoading = false;
  List<Map<String, String>> _searchResults = [];
  String _message = 'Search by interest or what people need...';


  // Categories for the Filter UI
  final List<String> _categories = ['All', 'Hiking', 'Coding', 'Needs Help', 'Travel'];
  String _selectedCategory = 'All';

  // Mock Database including "Shared Needs" (D#30 Requirement)
  final List<Map<String, String>> _allUsers = [
    {
      'userName': 'Alex Rivera', 
      'interests': 'Hiking, Nature, Photography', 
      'needs': 'Hiking Partner', 
      'category': 'Hiking'
    },
    {
      'userName': 'Jordan Smith', 
      'interests': 'Coding, Sci-Fi, Python', 
      'needs': 'Project Mentor', 
      'category': 'Coding'
    },
    {
      'userName': 'Taylor Swift', 
      'interests': 'Cooking, Travel, Singing', 
      'needs': 'Local Guide', 
      'category': 'Travel'
    },
    {
      'userName': 'Casey Jones', 
      'interests': 'Fitness, Gym, Weights', 
      'needs': 'Workout Partner', 
      'category': 'Needs Help'
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _allUsers;
  }

  void _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
      _message = '';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final results = _allUsers.where((user) {
      final matchesQuery = user['userName']!.toLowerCase().contains(query) || 
                           user['interests']!.toLowerCase().contains(query) ||
                           user['needs']!.toLowerCase().contains(query);
      

      final matchesCategory = _selectedCategory == 'All' || 
                              user['category'] == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    setState(() {
      _isLoading = false;
      _searchResults = results;
      if (_searchResults.isEmpty) {
        _message = 'No one found matching "$query" in $_selectedCategory';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blue,
                  hintText: 'Search interests or needs...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _performSearch,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = category;
                          _performSearch();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _searchResults.isEmpty
                      ? Center(child: Text(_message))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  user['userName']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Interests: ${user['interests']}'),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue, width: 0.5),
                                      ),
                                      child: Text(
                                        'SHARING NEED: ${user['needs']}',
                                        style: const TextStyle(
                                          fontSize: 11, 
                                          color: Colors.blue, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}