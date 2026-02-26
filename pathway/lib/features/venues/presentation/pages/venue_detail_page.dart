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
      // Repository uses venueId (int) and current bool status
      await _repo.toggleSave(venue.id, venue.isSaved);
      _refresh(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update favorite status")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE), // Slightly lighter bg
        appBar: AppBar(
          title: const Text('Venue Details', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          actions: [
            FutureBuilder<VenueModel?>(
              future: _venueFuture,
              initialData: widget.initialVenue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
                
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
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Reviews'),
              Tab(text: 'Posts'),
            ],
          ),
        ),
        body: FutureBuilder<VenueModel?>(
          future: _venueFuture,
          initialData: widget.initialVenue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading venue: ${snapshot.error}'));
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
    // Correctly build address from the new model fields
    final addressParts = [
      if (venue.addressLine1 != null && venue.addressLine1!.isNotEmpty) venue.addressLine1,
      if (venue.city != null && venue.city!.isNotEmpty) venue.city,
    ];
    final fullAddress = addressParts.join(', ');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title & Address Section
        Text(venue.name, 
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                fullAddress.isNotEmpty ? fullAddress : 'No address provided',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Quick Badges
        Row(
          children: [
            _Badge(text: venue.category ?? 'Venue', color: Colors.deepPurple),
            const SizedBox(width: 10),
            _Badge(
              text: '${venue.averageRating.toStringAsFixed(1)} (${venue.totalReviews})', 
              icon: Icons.star_rounded,
              color: Colors.amber[800]!,
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text('Accessibility Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        venue.tags.isEmpty 
          ? const Text("No accessibility information provided yet.", style: TextStyle(color: Colors.grey))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: venue.tags.map((tag) => _FeatureChip(label: tag)).toList(),
            ),

        const SizedBox(height: 24),
        const Text('Venue Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            venue.imageUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Text('About this Venue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _PlaceholderCard(
          child: Text(
            venue.description ?? 'A welcoming space for everyone. Detailed description coming soon.', 
            style: TextStyle(height: 1.6, color: Colors.grey[800], fontSize: 15),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ... _ReviewsTab and _PostsTab remain placeholders for now ...
class _ReviewsTab extends StatelessWidget {
  final VenueModel venue;
  const _ReviewsTab({required this.venue});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Reviews coming soon"));
}

class _PostsTab extends StatelessWidget {
  final VenueModel venue;
  const _PostsTab({required this.venue});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Posts coming soon"));
}

/* -------------------- Custom UI Components -------------------- */

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final Widget child;
  const _PlaceholderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  const _Badge({required this.text, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}