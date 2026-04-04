import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/venue_model.dart';
import '../../data/venue_repository.dart';
import '../../data/review_model.dart';
import '../../data/venue_overview_generator.dart';
import '../../../../features/reviews/data/review_moderator.dart';

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
          _OverviewTab(venue: venue, onPhotoUploaded: _refresh),
          _ReviewsTab(venue: venue, onReviewAdded: _refresh),
          _PostsTab(venue: venue),
        ],
      ),
    );
  }
}

/* -------------------- Tabs -------------------- */

class _OverviewTab extends StatefulWidget {
  final VenueModel venue;
  final VoidCallback onPhotoUploaded;

  const _OverviewTab({required this.venue, required this.onPhotoUploaded});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _repo = VenueRepository();
  bool _uploadingPhoto = false;
  bool _uploadingVideo = false;

  VenueModel get venue => widget.venue;

  Future<String>? _overviewFuture;

  void _refreshOverview() {
    _overviewFuture = _repo
        .fetchVenueReviews(widget.venue.id)
        .then((reviews) => VenueOverviewGenerator.generateOverview(reviews));
  }

  @override
  void initState() {
    super.initState();
    _refreshOverview();
  }

  @override
  void didUpdateWidget(_OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.venue.totalReviews != oldWidget.venue.totalReviews) {
      setState(_refreshOverview);
    }
  }

  Future<void> _uploadVenuePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final path = 'venues/${venue.id}/cover.$ext';
      await _repo.uploadToStorage(path, bytes);
      await _repo.updateVenueImagePath(venue.id, path);
      widget.onPhotoUploaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _uploadVenueVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingVideo = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final path = 'venues/${venue.id}/video.$ext';
      await _repo.uploadToStorage(path, bytes);
      await _repo.updateVenueVideoPath(venue.id, path);
      widget.onPhotoUploaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null &&
        venue.createdByUserId == currentUserId;

    final hasCoords = venue.latitude != null && venue.longitude != null;
    final hasAddress =
        (venue.addressLine1 ?? '').trim().isNotEmpty ||
        (venue.city ?? '').trim().isNotEmpty ||
        (venue.zipCode ?? '').trim().isNotEmpty;

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
                        '${venue.averageRating.toStringAsFixed(1)} ★ • ${venue.totalReviews} review${venue.totalReviews == 1 ? '' : 's'}',
                    icon: Icons.star_rounded,
                    color: Colors.amber[800]!,
                  ),
          ],
        ),
        const SizedBox(height: 16),
        _AccessibilityScoreCard(venue: venue),

        const SizedBox(height: 14),

        _Card(
          title: 'AI Overview',
          child: FutureBuilder<String>(
            future: _overviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      snapshot.data ?? 'Unable to generate overview.',
                      style: TextStyle(height: 1.6, color: Colors.grey[800], fontSize: 15),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        _Card(
          title: 'Photos & Videos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    venue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text(
                        'Image unavailable',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              if (venue.videoPath != null && venue.videoPath!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _VideoTile(url: _repo.getPublicUrl(venue.videoPath!)),
              ],
              if (isOwner) ...[
                const SizedBox(height: 10),
                if (_uploadingPhoto || _uploadingVideo)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploadVenuePhoto,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Upload Photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _uploadVenueVideo,
                        icon: const Icon(Icons.video_call, size: 18),
                        label: const Text('Upload Video'),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),
        _Card(
          title: 'Accessibility Features',
          child: venue.tags.isEmpty
              ? const Text(
                  "No accessibility information provided yet.",
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: venue.tags
                          .map((tag) => _FeatureChip(label: tag))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Based on community reports and reviews.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
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
                value: hasCoords
                    ? '${venue.latitude}, ${venue.longitude}'
                    : '—',
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: (hasCoords || hasAddress)
                    ? () => _openMapsForVenue(context, venue)
                    : null,
                onLongPress: (hasCoords || hasAddress)
                    ? () => _copyVenueLocation(context, venue)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formattedAddress(venue),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: (hasCoords || hasAddress)
                        ? () => _openMapsForVenue(context, venue)
                        : null,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                  OutlinedButton.icon(
                    onPressed: (hasCoords || hasAddress)
                        ? () => _copyVenueLocation(context, venue)
                        : null,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _openMapsForVenue(
    BuildContext context,
    VenueModel v,
  ) async {
    final hasCoords = v.latitude != null && v.longitude != null;

    final query = hasCoords
        ? '${v.latitude},${v.longitude}'
        : [
            if (v.addressLine1 != null && v.addressLine1!.trim().isNotEmpty)
              v.addressLine1!.trim(),
            if (v.city != null && v.city!.trim().isNotEmpty) v.city!.trim(),
            if (v.zipCode != null && v.zipCode!.trim().isNotEmpty)
              v.zipCode!.trim(),
          ].join(', ');

    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location data available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Maps.')));
    }
  }

  static String _formattedAddress(VenueModel v) {
    final parts = <String>[
      if (v.addressLine1 != null && v.addressLine1!.trim().isNotEmpty)
        v.addressLine1!.trim(),
      if (v.city != null && v.city!.trim().isNotEmpty) v.city!.trim(),
      if (v.zipCode != null && v.zipCode!.trim().isNotEmpty) v.zipCode!.trim(),
    ];

    if (parts.isNotEmpty) return parts.join(', ');

    // fallback to coords if no address
    if (v.latitude != null && v.longitude != null) {
      return '${v.latitude}, ${v.longitude}';
    }

    return '—';
  }

  static Future<void> _copyVenueLocation(
    BuildContext context,
    VenueModel v,
  ) async {
    final text = [
      if (v.addressLine1 != null && v.addressLine1!.trim().isNotEmpty)
        v.addressLine1!.trim(),
      if (v.city != null && v.city!.trim().isNotEmpty) v.city!.trim(),
      if (v.zipCode != null && v.zipCode!.trim().isNotEmpty) v.zipCode!.trim(),
      if (v.latitude != null && v.longitude != null)
        '(${v.latitude}, ${v.longitude})',
    ].join(' • ');

    if (text.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location copied.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copy failed on this platform.')),
        );
      }
    }
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

  String _sortMode = 'newest';

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _repo.fetchVenueReviews(
      widget.venue.id,
      sortMode: _sortMode,
    );
  }

  Future<bool> _confirmDeleteReview() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _refresh() async {
    setState(() {
      _reviewsFuture = _repo.fetchVenueReviews(
        widget.venue.id,
        sortMode: _sortMode,
      );
    });
  }

  Future<void> _openAddReview() async {
    final result = await showDialog<_ReviewDraft>(
      context: context,
      builder: (_) => const _AddReviewDialog(),
    );

    if (result == null) return;

    try {
      final reviewId = await _repo.addVenueReview(
        venueId: widget.venue.id,
        rating: result.rating,
        text: result.text,
      );

      if (result.photo != null) {
        final bytes = await result.photo!.readAsBytes();
        final ext = result.photo!.name.split('.').last.toLowerCase();
        final mime = _mimeFromExtension(ext);
        final path = 'reviews/$reviewId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final url = await _repo.uploadToStorage(path, bytes, contentType: mime);
        await _repo.addReviewPhoto(reviewId, url);
      }

      if (result.video != null) {
        final bytes = await result.video!.readAsBytes();
        final ext = result.video!.name.split('.').last.toLowerCase();
        final mime = _mimeFromExtension(ext);
        final path = 'reviews/$reviewId/video_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final url = await _repo.uploadToStorage(path, bytes, contentType: mime);
        await _repo.addReviewPhoto(reviewId, url);
      }

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
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),

                  // Styled sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortMode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text('Oldest'),
                          ),
                          DropdownMenuItem(
                            value: 'highest',
                            child: Text('Highest'),
                          ),
                          DropdownMenuItem(
                            value: 'lowest',
                            child: Text('Lowest'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _sortMode = v;
                            _reviewsFuture = _repo.fetchVenueReviews(
                              widget.venue.id,
                              sortMode: _sortMode,
                            );
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _openAddReview,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Write'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
                ...reviews.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(
                      review: r,
                      canManage:
                          currentUserId != null && r.userId == currentUserId,
                      onDelete: () async {
                        final ok = await _confirmDeleteReview();
                        if (!ok) return;
                        await _repo.deleteReview(r.id);
                        await _refresh();
                      },

                      onEdit: () async {
                        final result = await showDialog<_ReviewDraft>(
                          context: context,
                          builder: (_) => _EditReviewDialog(
                            initialRating: r.rating,
                            initialText: r.text,
                          ),
                        );

                        if (result == null) return;

                        try {
                          await _repo.updateReview(
                            reviewId: r.id,
                            rating: result.rating,
                            text: result.text,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Review updated.")),
                            );
                          }
                          await _refresh();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Edit failed: $e")),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool canManage;

  // Use VoidCallback so IconButton.onPressed is happy.
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ReviewCard({
    required this.review,
    required this.canManage,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = review.createdAt == null
        ? ""
        : "${review.createdAt!.month}/${review.createdAt!.day}/${review.createdAt!.year}";

    final body = (review.text ?? "").trim();

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
        border: Border.all(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(rating: review.rating),
              const Spacer(),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),

          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(height: 1.4, fontSize: 14.5)),
          ],

          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.photos[i],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (review.videos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _VideoTile(url: review.videos[i]),
              ),
            ),
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

class _VideoTile extends StatefulWidget {
  final String url;
  const _VideoTile({required this.url});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_ready) return;
        setState(() {
          _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
        });
      },
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_ready)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _ctrl.value.size.width,
                      height: _ctrl.value.size.height,
                      child: VideoPlayer(_ctrl),
                    ),
                  ),
                ),
              if (!_ready)
                const CircularProgressIndicator(color: Colors.white),
              if (_ready && !_ctrl.value.isPlaying)
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 36,
                ),
            ],
          ),
        ),
      ),
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

class _AccessibilityScoreCard extends StatelessWidget {
  final VenueModel venue;
  const _AccessibilityScoreCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final score = _computeAccessibilityScore(venue);
    final label = _scoreLabel(score);
    final caption = _scoreCaption(score, venue.totalReviews);

    return _Card(
      title: 'Accessibility Score',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(score: score),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tooltip(
                message:
                    'Score is estimated from accessibility tags and review rating.\n'
                    'More community data improves confidence.',
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            caption,
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.accessible_forward, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$score/100',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// Heuristic scoring:
/// - Starts at 50
/// - Adds points for known positive tags
/// - Uses averageRating as a gentle multiplier
/// - Applies a small confidence penalty if very few reviews
int _computeAccessibilityScore(VenueModel v) {
  int score = 50;

  final tags = v.tags.map((e) => e.toLowerCase().trim()).toList();

  // Positive feature tags (adjust as your tag set evolves)
  const positiveWeights = <String, int>{
    'wheelchair accessible': 18,
    'wheelchair': 14,
    'ramp': 10,
    'elevator': 10,
    'accessible restroom': 14,
    'restroom': 8,
    'braille': 8,
    'asl': 8,
    'sign language': 8,
    'hearing loop': 8,
    'wide door': 6,
    'automatic door': 6,
    'step-free': 12,
    'no steps': 12,
    'accessible parking': 10,
    'parking': 4,
    'seating available': 4,
    'quiet': 3,
    'low sensory': 6,
  };

  // Negative tags (if you have them)
  const negativeWeights = <String, int>{
    'not wheelchair accessible': -18,
    'stairs only': -16,
    'no elevator': -12,
    'narrow': -6,
    'no ramp': -10,
    'inaccessible restroom': -14,
  };

  for (final t in tags) {
    positiveWeights.forEach((key, w) {
      if (t.contains(key)) score += w;
    });
    negativeWeights.forEach((key, w) {
      if (t.contains(key)) score += w;
    });
  }

  // Use rating as a gentle influence (centers at ~3.5)
  // Clamp rating to 0..5 just in case.
  final r = v.averageRating.clamp(0.0, 5.0);
  // Example: 0★ -> -8, 3.5★ -> ~0, 5★ -> +6
  score += ((r - 3.5) * 4).round();

  // Confidence: fewer reviews = slightly less confident -> small penalty
  if (v.totalReviews == 0) score -= 10;
  if (v.totalReviews == 1) score -= 6;
  if (v.totalReviews == 2) score -= 3;

  // Clamp to 0..100
  if (score < 0) score = 0;
  if (score > 100) score = 100;
  return score;
}

String _mimeFromExtension(String ext) {
  switch (ext) {
    case 'mov':
      return 'video/quicktime';
    case 'mp4':
      return 'video/mp4';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

String _scoreLabel(int score) {
  if (score >= 85) return 'Excellent accessibility';
  if (score >= 70) return 'Good accessibility';
  if (score >= 55) return 'Mixed accessibility';
  if (score >= 40) return 'Limited accessibility';
  return 'Low accessibility';
}

String _scoreCaption(int score, int reviewCount) {
  final base = reviewCount == 0
      ? 'No reviews yet — score is an estimate based on tags.'
      : 'Based on tags and $reviewCount review${reviewCount == 1 ? '' : 's'}.';
  if (score >= 70) return '$base Looks promising for many users.';
  if (score >= 55)
    return '$base Some users may have difficulties — check details.';
  return '$base May be challenging — verify before visiting.';
}

Color _scoreColor(int score) {
  if (score >= 85) return Colors.green.shade700;
  if (score >= 70) return Colors.teal.shade700;
  if (score >= 55) return Colors.amber.shade800;
  if (score >= 40) return Colors.orange.shade800;
  return Colors.red.shade700;
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
  final XFile? photo;
  final XFile? video;
  _ReviewDraft({required this.rating, this.text, this.photo, this.video});
}

class _AddReviewDialog extends StatefulWidget {
  const _AddReviewDialog();

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _EditReviewDialog extends StatefulWidget {
  final int initialRating;
  final String? initialText;

  const _EditReviewDialog({
    required this.initialRating,
    required this.initialText,
  });

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late int _rating;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _rating >= 1 && _rating <= 5;

    return AlertDialog(
      title: const Text("Edit review"),
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
                onChanged: (v) => setState(() => _rating = v ?? _rating),
              ),
            ],
          ),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Update your review (optional)",
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
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 5;
  final _controller = TextEditingController();
  XFile? _photo;
  XFile? _video;

  final ReviewModerator _moderator = ReviewModerator();
  bool _isTraining = true;
  String? _statusMessage;
  Color _statusColor = Colors.transparent;
  bool _blocked = false;
  bool _flagged = false;

  @override
  void initState() {
    super.initState();
    _moderator.train().then((_) {
      if (mounted) {
        setState(() {
          _isTraining = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _video = picked);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _rating >= 1 && _rating <= 5;

    return AlertDialog(
      title: const Text("Write a review"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_statusMessage != null) ...[              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: TextStyle(color: _statusColor, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo, size: 18),
                  label: const Text("Add Photo"),
                ),
                if (_photo != null) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _photo!.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text("Add Video"),
                ),
                if (_video != null) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _video!.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: (_isTraining || !canSubmit || _blocked)
              ? null
              : () {
                  final text = _controller.text.trim();

                  // If already flagged and user presses again, submit anyway
                  if (_flagged) {
                    Navigator.pop(
                      context,
                      _ReviewDraft(
                        rating: _rating,
                        text: _controller.text,
                        photo: _photo,
                        video: _video,
                      ),
                    );
                    return;
                  }

                  // Run moderation if model is trained and text is not empty
                  if (_moderator.isTrained && text.isNotEmpty) {
                    final result = _moderator.moderateContent(text);

                    if (result.action == ModerationAction.blocked) {
                      setState(() {
                        _statusMessage = 'Blocked: ${result.reason}';
                        _statusColor = Colors.red;
                        _blocked = true;
                      });
                      return;
                    }

                    if (result.action == ModerationAction.flagged) {
                      setState(() {
                        _statusMessage = 'Warning: ${result.reason}. Press Submit again to post anyway.';
                        _statusColor = Colors.orange;
                        _flagged = true;
                      });
                      return;
                    }
                  }

                  Navigator.pop(
                    context,
                    _ReviewDraft(
                      rating: _rating,
                      text: _controller.text,
                      photo: _photo,
                      video: _video,
                    ),
                  );
                },
          child: _isTraining
              ? const Text("Training AI...")
              : _flagged
                  ? const Text("Submit Anyway")
                  : const Text("Submit"),
        ),
      ],
    );
  }

  Future<void> openMapsForVenue(VenueModel v) async {
    final hasCoords = v.latitude != null && v.longitude != null;

    // Prefer coords if available; otherwise use address text.
    final query = hasCoords
        ? '${v.latitude},${v.longitude}'
        : [
            if (v.addressLine1 != null && v.addressLine1!.trim().isNotEmpty)
              v.addressLine1!.trim(),
            if (v.city != null && v.city!.trim().isNotEmpty) v.city!.trim(),
            if (v.zipCode != null && v.zipCode!.trim().isNotEmpty)
              v.zipCode!.trim(),
          ].join(', ');

    if (query.trim().isEmpty) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      // Fallback: try in-app webview/tab
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> copyVenueLocation(BuildContext context, VenueModel v) async {
    final text = [
      if (v.addressLine1 != null && v.addressLine1!.trim().isNotEmpty)
        v.addressLine1!.trim(),
      if (v.city != null && v.city!.trim().isNotEmpty) v.city!.trim(),
      if (v.zipCode != null && v.zipCode!.trim().isNotEmpty) v.zipCode!.trim(),
      if (v.latitude != null && v.longitude != null)
        '(${v.latitude}, ${v.longitude})',
    ].join(' • ');

    if (text.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location copied.')));
    }
  }
}
