import 'package:flutter/material.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';
import 'package:pathway/features/venues/data/venue_suggestion_model.dart';

class VenueSuggestionsPage extends StatefulWidget {
  const VenueSuggestionsPage({super.key});

  @override
  State<VenueSuggestionsPage> createState() => _VenueSuggestionsPageState();
}

class _VenueSuggestionsPageState extends State<VenueSuggestionsPage> {
  final VenueRepository _repo = VenueRepository();
  late Future<List<VenueSuggestionModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchPendingVenueSuggestions();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchPendingVenueSuggestions();
    });
  }

  Future<void> _approve(String suggestionId) async {
    try {
      await _repo.approveVenueSuggestion(suggestionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggestion approved.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _reject(String suggestionId) async {
    try {
      await _repo.rejectVenueSuggestion(suggestionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggestion rejected.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }

  String _prettyField(String fieldName) {
    switch (fieldName) {
      case 'venue_name':
        return 'Venue Name';
      case 'address':
        return 'Address';
      case 'description':
        return 'Description';
      case 'phone_number':
        return 'Phone Number';
      case 'website_url':
        return 'Website URL';
      case 'accessibility_notes':
        return 'Accessibility Notes';
      default:
        return fieldName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Suggestions'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VenueSuggestionModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final suggestions = snapshot.data ?? [];

            if (suggestions.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No pending suggestions.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = suggestions[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.black12.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venue ID: ${s.venueId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Field: ${_prettyField(s.fieldName)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Suggested value:',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.proposedValue,
                        style: const TextStyle(fontSize: 14.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _reject(s.suggestionId),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _approve(s.suggestionId),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}