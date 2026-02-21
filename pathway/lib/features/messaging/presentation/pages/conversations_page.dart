import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/user_profile.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<UserProfile> _searchResults = [];
  bool _isQuerying = false;

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isQuerying = true);

    try {
    
      final data = await _supabase
          .schema('pathway')
          .from('profiles') 
          .select()
          .or('display_name.ilike.%$query%,bio.ilike.%$query%');

      setState(() {
  _searchResults = (data as List)
      .map((json) => UserProfile.fromJson(json)) // Much cleaner!
      .toList();
  _isQuerying = false;
});
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() => _isQuerying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _handleSearch,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Search students...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              )
            : const Text(
                "Messages",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.deepPurple,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: _isSearching ? _buildSearchList() : _buildInbox(),
    );
  }

  Widget _buildSearchList() {
    if (_isQuerying) return const Center(child: CircularProgressIndicator());

    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return const Center(child: Text("No students found."));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final user = _searchResults[i];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.shade50,
            child: Text(
              user.userName.isNotEmpty ? user.userName[0] : '?',
              style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            user.userName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(user.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () {
            // This will link to your messaging system later
            debugPrint(
"Start conversation with: ${user.userName} (ID: ${user.id})");
          },
        );
      },
    );
  }

  Widget _buildInbox() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          // Links to your conversations table
          Text("No active conversations", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text("Search for a user to start chatting", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}