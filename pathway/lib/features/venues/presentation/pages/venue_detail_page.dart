import 'package:flutter/material.dart';
import '../../data/venue_model.dart';
import '../../data/venue_repository.dart';

class VenueDetailPage extends StatefulWidget {
  final int venueId;
  final VenueModel? initialVenue;

  const VenueDetailPage({super.key, required this.venueId, this.initialVenue});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  final _repo = VenueRepository();
  
  // FIXED: Variable is now nullable to match the Repository return type
  late Future<VenueModel?> _venueFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _venueFuture = _repo.fetchVenueById(widget.venueId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _toggleSave(VenueModel venue) async {
    try {
      await _repo.toggleSave(widget.venueId, venue.isSaved);
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update favorite status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9ECF7),
        appBar: AppBar(
          title: const Text('Venue Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          actions: [
            // FIXED: FutureBuilder type is now <VenueModel?>
            FutureBuilder<VenueModel?>(
              future: _venueFuture,
              initialData: widget.initialVenue,
              builder: (context, snapshot) {
                // Return empty if data isn't here yet or venue doesn't exist
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                
                final venue = snapshot.data!;
                return IconButton(
                  icon: Icon(
                    venue.isSaved ? Icons.favorite : Icons.favorite_border,
                    color: venue.isSaved ? Colors.red : Colors.black,
                  ),
                  onPressed: () => _toggleSave(venue),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.deepPurple,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Reviews'),
              Tab(text: 'Posts'),
            ],
          ),
        ),
        // FIXED: FutureBuilder type is now <VenueModel?>
        body: FutureBuilder<VenueModel?>(
          future: _venueFuture,
          initialData: widget.initialVenue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Venue not found.'));
            }

            final venue = snapshot.data!;
            return TabBarView(
              children: [
                _OverviewTab(venue: venue),
                _ReviewsTab(venue: venue),
                _PostsTab(venue: venue),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* -------------------- Tabs -------------------- */

class _OverviewTab extends StatelessWidget {
  final VenueModel venue;
  const _OverviewTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    final address = [
      if (venue.addressLine1 != null && venue.addressLine1!.isNotEmpty) venue.addressLine1,
      if (venue.city != null && venue.city!.isNotEmpty) venue.city,
    ].join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(venue.name, 
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(address.isNotEmpty ? address : 'Address not available'),
        const SizedBox(height: 14),
        
        Row(
          children: [
            _Badge(text: venue.category ?? 'General'),
            const SizedBox(width: 10),
            _Badge(text: 'Rating: ${venue.averageRating.toStringAsFixed(1)}', icon: Icons.star),
          ],
        ),

        const SizedBox(height: 16),
        const Text('Accessibility Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        
        venue.tags.isEmpty 
          ? const Text("No tags listed", style: TextStyle(color: Colors.grey))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: venue.tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
              )).toList(),
            ),

        const SizedBox(height: 18),
        const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            venue.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _PlaceholderCard(
              height: 200, 
              child: Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40))
            ),
          ),
        ),

        const SizedBox(height: 18),
        const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _PlaceholderCard(
          child: Text(venue.description ?? 'No description available.', 
            style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final VenueModel venue;
  const _ReviewsTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Reviews for ${venue.name} coming soon"));
  }
}

class _PostsTab extends StatelessWidget {
  final VenueModel venue;
  const _PostsTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Community posts for ${venue.name} coming soon"));
  }
}

/* -------------------- Shared UI -------------------- */

class _PlaceholderCard extends StatelessWidget {
  final Widget child;
  final double? height;
  const _PlaceholderCard({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Badge({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: Colors.amber),
          if (icon != null) const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}