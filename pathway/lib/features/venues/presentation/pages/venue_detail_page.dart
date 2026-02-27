import 'package:flutter/material.dart';
import '../../data/venue_model.dart';
import '../../data/venue_repository.dart';
import '../../data/review_model.dart';

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
    setState(_loadData);
  }

  Future<void> _toggleSave(VenueModel venue) async {
    try {
      await _repo.toggleSave(venue.id, venue.isSaved);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update favorite status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: FutureBuilder<VenueModel?>(
        future: _venueFuture,
        initialData: widget.initialVenue,
        builder: (context, snapshot) {
          final venue = snapshot.data;

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FE),
            floatingActionButton: (venue == null)
                ? null
                : AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: venue.isSaved ? 1.1 : 1.0,
                    child: FloatingActionButton(
                      heroTag: 'fav_fab_${venue.id}',
                      backgroundColor: Colors.white,
                      elevation: 6,
                      onPressed: () => _toggleSave(venue),
                      child: Icon(
                        venue.isSaved ? Icons.favorite : Icons.favorite_border,
                        color: venue.isSaved ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(snapshot),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<VenueModel?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text('Error loading venue: ${snapshot.error}')),
        ],
      );
    }
    if (!snapshot.hasData || snapshot.data == null) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Venue not found.')),
        ],
      );
    }

    final venue = snapshot.data!;

    final addressParts = [
      if (venue.addressLine1 != null && venue.addressLine1!.isNotEmpty)
        venue.addressLine1!,
      if (venue.city != null && venue.city!.isNotEmpty) venue.city!,
      if (venue.zipCode != null && venue.zipCode!.isNotEmpty) venue.zipCode!,
    ];
    final fullAddress = addressParts.isEmpty
        ? 'No address provided'
        : addressParts.join(', ');

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            pinned: true,
            elevation: 0,
            expandedHeight: 260,
            title: innerBoxIsScrolled
                ? Text(
                    venue.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    venue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  // gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                  // title/address overlay
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        children: [
          _OverviewTab(venue: venue),
          _ReviewsTab(venue: venue, onReviewAdded: _refresh),
          _PostsTab(venue: venue),
        ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            _Badge(text: venue.category ?? 'Venue', color: Colors.deepPurple),
            const SizedBox(width: 10),
            venue.totalReviews == 0
                ? _Badge(text: 'NEW • NO REVIEWS', color: Colors.grey[700]!)
                : _Badge(
                    text:
                        '${venue.averageRating.toStringAsFixed(1)} (${venue.totalReviews})',
                    icon: Icons.star_rounded,
                    color: Colors.amber[800]!,
                  ),
          ],
        ),
        const SizedBox(height: 16),

        _Card(
          title: 'Accessibility Features',
          child: venue.tags.isEmpty
              ? const Text(
                  "No accessibility information provided yet.",
                  style: TextStyle(color: Colors.grey),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: venue.tags
                      .map((tag) => _FeatureChip(label: tag))
                      .toList(),
                ),
        ),

        const SizedBox(height: 14),

        _Card(
          title: 'About this Venue',
          child: Text(
            (venue.description == null || venue.description!.trim().isEmpty)
                ? 'A welcoming space for everyone. Detailed description coming soon.'
                : venue.description!,
            style: TextStyle(
              height: 1.6,
              color: Colors.grey[800],
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(height: 14),

        _Card(
          title: 'Location',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.location_city,
                label: 'City',
                value: venue.city ?? '—',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.local_post_office,
                label: 'Zip Code',
                value: venue.zipCode ?? '—',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.my_location,
                label: 'Coordinates',
                value: (venue.latitude != null && venue.longitude != null)
                    ? '${venue.latitude}, ${venue.longitude}'
                    : '—',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  final VenueModel venue;
  final Future<void> Function() onReviewAdded;

  const _ReviewsTab({required this.venue, required this.onReviewAdded});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _repo = VenueRepository();
  late Future<List<ReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _repo.fetchVenueReviews(widget.venue.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _reviewsFuture = _repo.fetchVenueReviews(widget.venue.id);
    });
  }

  Future<void> _openAddReview() async {
    final result = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => const _AddReviewDialog(),
    );

    if (result == null) return;

    try {
      await _repo.addVenueReview(
        venueId: widget.venue.id,
        rating: result.rating,
        text: result.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Review submitted.")));
      }

      await widget.onReviewAdded(); // refresh parent venue (rating)
      await _refresh(); // refresh review list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Review failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _openAddReview,
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text("Write"),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      "No reviews yet.\nBe the first to leave one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...reviews.map((r) => _ReviewCard(review: r)),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateText = review.createdAt == null
        ? ""
        : "${review.createdAt!.month}/${review.createdAt!.day}/${review.createdAt!.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(rating: review.rating),
              const Spacer(),
              if (dateText.isNotEmpty)
                Text(dateText, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          if ((review.text ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.text!.trim(), style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating.clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < r ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: Colors.amber,
        );
      }),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final VenueModel venue;
  const _PostsTab({required this.venue});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Posts coming soon"));
  }
}

/* -------------------- UI Components -------------------- */

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

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
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.deepPurple,
          fontWeight: FontWeight.w700,
        ),
      ),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDraft {
  final int rating;
  final String? text;
  _ReviewDraft({required this.rating, this.text});
}

class _AddReviewDialog extends StatefulWidget {
  const _AddReviewDialog();

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 5;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _rating >= 1 && _rating <= 5;

    return AlertDialog(
      title: const Text("Write a review"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text("Rating: "),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rating,
                items: [1, 2, 3, 4, 5]
                    .map((v) => DropdownMenuItem(value: v, child: Text("$v")))
                    .toList(),
                onChanged: (v) => setState(() => _rating = v ?? 5),
              ),
            ],
          ),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "What was it like? (optional)",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: !canSubmit
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _ReviewDraft(rating: _rating, text: _controller.text),
                  );
                },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
