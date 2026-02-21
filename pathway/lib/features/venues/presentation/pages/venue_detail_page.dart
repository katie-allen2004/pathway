import 'package:flutter/material.dart';
import '../../data/venue_model.dart';
import '../../data/venue_repository.dart';

class VenueDetailPage extends StatefulWidget {
  final String venueId;
  final VenueModel? initialVenue;

  const VenueDetailPage({super.key, required this.venueId, this.initialVenue});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  final _repo = VenueRepository();
  late Future<VenueModel> _venueFuture;

  @override
  void initState() {
    super.initState();
    _venueFuture = _repo.fetchVenueById(widget.venueId);
  }

  Future<void> _refresh() async {
    setState(() {
      _venueFuture = _repo.fetchVenueById(widget.venueId);
    });
  }

  Future<void> _toggleSave(VenueModel venue) async {
    await _repo.toggleSave(widget.venueId, venue.isSaved);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9ECF7),
        appBar: AppBar(
          title: const Text('Venue Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          actions: [
            // Heart button that reflects current saved state
            FutureBuilder<VenueModel>(
              future: _venueFuture,
              initialData: widget.initialVenue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final venue = snapshot.data!;
                return IconButton(
                  tooltip: venue.isSaved ? 'Unsave' : 'Save',
                  icon: Icon(
                    venue.isSaved ? Icons.favorite : Icons.favorite_border,
                    color: venue.isSaved ? Colors.red : Colors.black,
                  ),
                  onPressed: () => _toggleSave(venue),
                );
              },
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Reviews'),
              Tab(text: 'Posts'),
            ],
          ),
        ),
        body: FutureBuilder<VenueModel>(
          future: _venueFuture,
          initialData: widget.initialVenue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading venue: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
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
      if (venue.addressLine1 != null && venue.addressLine1!.trim().isNotEmpty)
        venue.addressLine1!.trim(),
      if (venue.city != null && venue.city!.trim().isNotEmpty)
        venue.city!.trim(),
    ].join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          venue.name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),

        Text(
          address.isNotEmpty ? address : 'Address not available',
          style: TextStyle(
            fontSize: 14,
            color: address.isNotEmpty ? Colors.black87 : Colors.black54,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: const [
            _Badge(text: 'Accessibility: TBD'),
            SizedBox(width: 10),
            _Badge(text: 'Rating: TBD'),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          'Accessibility Tags',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('Ramp (TBD)')),
            Chip(label: Text('Accessible restroom (TBD)')),
            Chip(label: Text('Wide doors (TBD)')),
          ],
        ),

        const SizedBox(height: 18),

        const Text(
          'Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const _PlaceholderCard(
          height: 140,
          child: Center(child: Text('Photos placeholder')),
        ),

        const SizedBox(height: 18),

        const Text(
          'About',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _PlaceholderCard(
          child: Text(
            (venue.description != null && venue.description!.trim().isNotEmpty)
                ? venue.description!.trim()
                : 'No description available.',
          ),
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
    // Later: load from Supabase: reviews where venue_id = venue.id
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _PlaceholderCard(child: Text('Reviews coming soon (TBD)')),
      ],
    );
  }
}

class _PostsTab extends StatelessWidget {
  final VenueModel venue;
  const _PostsTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    // Later: load from Supabase: posts where venue_id = venue.id
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _PlaceholderCard(child: Text('Posts coming soon (TBD)')),
      ],
    );
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

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
