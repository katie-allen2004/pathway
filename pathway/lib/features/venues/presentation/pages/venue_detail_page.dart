import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/venue_model.dart';
import '../../data/venue_repository.dart';
import '../../data/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:pathway/features/gamification/data/badge_model.dart';
import 'package:pathway/features/venues/presentation/widgets/suggest_edit_dialog.dart';
import 'package:pathway/features/venues/data/venue_edit_history_model.dart';
import 'package:pathway/features/venues/data/venue_image_model.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ReviewShareHelper {
  // TODO: replace with your real production domain
  static const String _baseReviewUrl = 'https://pathway.app/reviews';

  static String reviewUrl(ReviewModel review) {
    return '$_baseReviewUrl/${review.id}';
  }

  static String shareText({
    required ReviewModel review,
    required String venueName,
  }) {
    final body = (review.text ?? '').trim();
    final rating = review.rating;
    final url = reviewUrl(review);

    final intro =
        'Check out this $rating-star review for $venueName on Pathway';
    if (body.isEmpty) {
      return '$intro\n\n$url';
    }

    return '$intro:\n"$body"\n\n$url';
  }

  static Future<void> copyReviewLink(
    BuildContext context, {
    required ReviewModel review,
  }) async {
    final url = reviewUrl(review);
    await Clipboard.setData(ClipboardData(text: url));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review link copied.')));
    }
  }

  static Future<void> shareReview(
    BuildContext context, {
    required ReviewModel review,
    required String venueName,
  }) async {
    final text = shareText(review: review, venueName: venueName);

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Pathway review for $venueName'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  static Future<void> shareToX(
    BuildContext context, {
    required ReviewModel review,
    required String venueName,
  }) async {
    final url = reviewUrl(review);

    final tweetText = 'Check out this review for $venueName on Pathway';

    final xUri = Uri.https('twitter.com', '/intent/tweet', {
      'text': tweetText,
      'url': url,
    });

    final ok = await launchUrl(xUri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open X.')));
    }
  }

  static Future<void> openInstagramWithCopiedLink(
    BuildContext context, {
    required ReviewModel review,
  }) async {
    final url = reviewUrl(review);

    // Copy first so the user can paste it into a DM/story workflow.
    await Clipboard.setData(ClipboardData(text: url));

    // Instagram app deep link.
    final instagramUri = Uri.parse('instagram://app');

    final opened = await launchUrl(
      instagramUri,
      mode: LaunchMode.externalApplication,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Instagram opened. Review link copied for paste.'
                : 'Instagram not available. Review link copied instead.',
          ),
        ),
      );
    }

    if (!opened) {
      final webUri = Uri.parse('https://www.instagram.com/');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> showShareSheet(
    BuildContext context, {
    required ReviewModel review,
    required String venueName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy review link'),
                onTap: () async {
                  Navigator.pop(context);
                  await copyReviewLink(context, review: review);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share...'),
                onTap: () async {
                  Navigator.pop(context);
                  await shareReview(
                    context,
                    review: review,
                    venueName: venueName,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.alternate_email_rounded),
                title: const Text('Share to X'),
                onTap: () async {
                  Navigator.pop(context);
                  await shareToX(context, review: review, venueName: venueName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Open Instagram'),
                subtitle: const Text('Copies the link so you can paste it'),
                onTap: () async {
                  Navigator.pop(context);
                  await openInstagramWithCopiedLink(context, review: review);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

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

  Future<void> _pickAndUploadVenueImage(VenueModel venue) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      final bytes = await file.readAsBytes();

      await _repo.uploadVenueImage(
        venueId: venue.id,
        bytes: bytes,
        fileName: file.name,
        isPrimary: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully.')),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _showSuggestEditDialog() async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) =>
          SuggestEditDialog(venueId: widget.venueId, repository: _repo),
    );

    if (!mounted) return;

    if (submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggestion submitted for review.')),
      );
    }
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return DefaultTabController(
      length: 3,
      child: FutureBuilder<VenueModel?>(
        future: _venueFuture,
        initialData: widget.initialVenue,
        builder: (context, snapshot) {
          final venue = snapshot.data;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            floatingActionButton: (venue == null)
                ? null
                : AnimatedScale(
                    duration: a11y.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    scale: venue.isSaved ? 1.1 : 1.0,
                    child: FloatingActionButton(
                      heroTag: 'fav_fab_${venue.id}',
                      backgroundColor: cs.surface,
                      elevation: a11y.highContrast ? 0 : 6,
                      onPressed: () => _toggleSave(venue),
                      child: Icon(
                        venue.isSaved ? Icons.favorite : Icons.favorite_border,
                        color: venue.isSaved ? cs.error : cs.onSurface,
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

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: innerBoxIsScrolled ? cs.onSurface : Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            pinned: true,
            elevation: 0,
            expandedHeight: 320,
            title: innerBoxIsScrolled
                ? Text(
                    venue.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            actions: [
              if (venue != null)
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  tooltip: 'Upload photo',
                  onPressed: () => _pickAndUploadVenueImage(venue),
                ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: innerBoxIsScrolled ? cs.onSurface : Colors.white,
                ),
                onPressed: _refresh,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(76),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _DetailTabs(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    venue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 72, // keeps location above the tabs
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
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
          _OverviewTab(venue: venue, onSuggestEdit: _showSuggestEditDialog),
          _ReviewsTab(venue: venue, onReviewAdded: _refresh),
          _PostsTab(venue: venue),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    const labels = ['Overview', 'Reviews', 'Posts'];

    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentIndex = controller.index;

        return Row(
          children: List.generate(labels.length, (index) {
            final selected = index == currentIndex;

            // dark mode: selected: purp bg + black text
            // unselected: black bg + white text

            final bg = selected
                ? (a11y.highContrast ? Colors.black : cs.primary)
                : (a11y.darkMode
                      ? theme.scaffoldBackgroundColor
                      : Colors.white);

            final fg = selected
                ? (a11y.darkMode ? Colors.black : Colors.white)
                : (a11y.highContrast ? Colors.black : cs.primary);

            // Normal:
            //  - Selected: primary bg + white text/border
            //  - Unselected: white bg + primary text/border
            // High Contrast:
            //  - Selected: black bg + white text/border
            //  - Unselected: white bg + black text/border
            // Dark Mode:
            //   - Selected: primary bg + black text/border
            //   - Unselected: scaffold bg + white text/border
            final borderColor = selected
                ? (a11y.darkMode ? Colors.black : Colors.white)
                : (a11y.highContrast ? Colors.black : cs.primary);

            // final borderColor = a11y.highContrast ? Colors.black : cs.primary;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 8,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: a11y.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/* -------------------- Tabs -------------------- */

class _OverviewTab extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onSuggestEdit;

  const _OverviewTab({required this.venue, required this.onSuggestEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

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
            _Badge(
              text: venue.category ?? 'Venue',
              color: (a11y.highContrast ? Colors.black : cs.primary),
            ),
            const SizedBox(width: 10),
            venue.totalReviews == 0
                ? _Badge(
                    text: 'NEW • NO REVIEWS',
                    color: (a11y.highContrast
                        ? Colors.black
                        : Colors.grey[700]!),
                  )
                : _Badge(
                    text:
                        '${venue.averageRating.toStringAsFixed(1)} ★ • ${venue.totalReviews} review${venue.totalReviews == 1 ? '' : 's'}',
                    icon: Icons.star_rounded,
                    color: (a11y.highContrast
                        ? Colors.black
                        : Colors.amber[800]!),
                  ),
          ],
        ),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onSuggestEdit,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Suggest Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _AccessibilityScoreCard(venue: venue),
        const SizedBox(height: 14),

        _VenuePhotosCard(venue: venue),

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
              color: (a11y.darkMode ? Colors.white30 : Colors.black87)
                  .withValues(alpha: 0.9),
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
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: cs.primary),
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

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: (hasCoords || hasAddress)
                        ? () => _openMapsForVenue(context, venue)
                        : null,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      'Open in Maps',
                      style: TextStyle(
                        color: (a11y.darkMode ? Colors.white : cs.primary),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (hasCoords || hasAddress)
                        ? () => _copyVenueLocation(context, venue)
                        : null,
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(
                      'Copy',
                      style: TextStyle(
                        color: (a11y.darkMode ? Colors.white : cs.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _Card(
          title: 'Edit History',
          child: FutureBuilder<List<VenueEditHistoryModel>>(
            future: VenueRepository().fetchVenueEditHistory(venue.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return const Text(
                  'No edit history yet.',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: history.map((h) {
                  final oldText =
                      (h.oldValue == null || h.oldValue!.trim().isEmpty)
                      ? '—'
                      : h.oldValue!;
                  final newText =
                      (h.newValue == null || h.newValue!.trim().isEmpty)
                      ? '—'
                      : h.newValue!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.fieldName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$oldText → $newText',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                        if (h.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${h.createdAt!.month}/${h.createdAt!.day}/${h.createdAt!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const Divider(height: 18),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
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
  final Map<String, Set<int>> _animatedBadgeIdsByUser = {};
  late Future<List<ReviewModel>> _reviewsFuture;
  Map<String, List<BadgeModel>> _badgesByUser = {};
  String _sortMode = 'newest';

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _repo.fetchVenueReviews(
      widget.venue.id,
      sortMode: _sortMode,
    );
    _refresh(); // loads badges too
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
    try {
      final reviews = await _repo.fetchVenueReviews(
        widget.venue.id,
        sortMode: _sortMode,
      );

      final authorIds = reviews.map((r) => r.userId).toSet().toList();
      final badgesByUser = await _repo.fetchBadgesForUsers(authorIds);

      // Detect newly earned badges per user (for animation)
      for (final uid in badgesByUser.keys) {
        final newList = badgesByUser[uid] ?? const [];
        final oldList = _badgesByUser[uid] ?? const [];

        final oldIds = oldList.map((b) => b.badgeId).toSet();
        final newlyEarnedIds = newList
            .map((b) => b.badgeId)
            .where((id) => !oldIds.contains(id))
            .toSet();

        if (newlyEarnedIds.isNotEmpty) {
          _animatedBadgeIdsByUser[uid] = newlyEarnedIds;
        } else {
          _animatedBadgeIdsByUser.remove(uid);
        }
      }

      setState(() {
        _reviewsFuture = Future.value(reviews);
        _badgesByUser = badgesByUser;
      });
    } catch (e) {
      setState(() {
        _reviewsFuture = _repo.fetchVenueReviews(
          widget.venue.id,
          sortMode: _sortMode,
        );
      });
    }
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

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Review submitted.")));

      await widget.onReviewAdded(); // refresh parent venue (rating)
      await _refresh(); // refresh review list + badges
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Review failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;
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
                  Text(
                    'Reviews',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),

                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: a11y.highContrast ? Colors.white : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: a11y.highContrast
                            ? Colors.black
                            : cs.outline.withValues(alpha: 0.35),
                        width: a11y.highContrast ? 1.5 : 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortMode,
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
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => _sortMode = v);
                          await _refresh();
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
                      style: a11y.highContrast
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            )
                          : ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      "No reviews yet.\nBe the first to leave one!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                )
              else
                ...reviews.map((r) {
                  final badges =
                      _badgesByUser[r.userId] ?? const <BadgeModel>[];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(
                      review: r,
                      venueName: widget.venue.name,
                      badges: badges,
                      animateBadgeIds: _animatedBadgeIdsByUser[r.userId] ?? {},
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

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Review updated.")),
                          );

                          await _refresh();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Edit failed: $e")),
                          );
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String venueName;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<BadgeModel> badges;
  final Set<int> animateBadgeIds;

  const _ReviewCard({
    super.key,
    required this.review,
    required this.venueName,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.badges,
    required this.animateBadgeIds,
  });
  String _displayName(ReviewModel review) {
    final username = review.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    if (review.userId.length >= 6) {
      return review.userId.substring(0, 6);
    }

    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final dateText = review.createdAt == null
        ? ""
        : "${review.createdAt!.month}/${review.createdAt!.day}/${review.createdAt!.year}";

    final body = (review.text ?? "").trim();
    final visibleBadges = badges;
    final extraCount = (badges.length - visibleBadges.length).clamp(0, 999);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (a11y.darkMode ? theme.scaffoldBackgroundColor : Colors.white)
            .withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: a11y.highContrast
              ? Colors.black
              : cs.outline.withValues(alpha: 0.35),
          width: a11y.highContrast ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: Author row + badges
          Row(
            children: [
              Text(
                _displayName(review),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 10),

              if (badges.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...visibleBadges.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _MiniBadge(
                              badge: b,
                              animate: animateBadgeIds.contains(b.badgeId),
                            ),
                          );
                        }),

                        if (extraCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Text(
                              '+$extraCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              if (dateText.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Stars + actions row
          Row(
            children: [
              _Stars(rating: review.rating),
              const Spacer(),

              IconButton(
                tooltip: 'Share review',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () {
                  ReviewShareHelper.showShareSheet(
                    context,
                    review: review,
                    venueName: venueName,
                  );
                },
              ),

              // Report for non-owner
              if (!canManage)
                IconButton(
                  tooltip: 'Report Review',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => _showReportDialog(context, review),
                ),

              // Edit/Delete for owner
              if (canManage) ...[
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
            Text(
              body,
              style: TextStyle(
                height: 1.4,
                fontSize: 14.5,
                color: (a11y.darkMode ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: 'venue_reviews',
        targetId: review.id,
        reportedUserId: review.userId,
      ),
    );
  }
}

/// Small pill used to render badges next to the user's name
class _MiniBadge extends StatefulWidget {
  final BadgeModel badge;
  final bool animate;

  const _MiniBadge({required this.badge, this.animate = false, super.key});

  @override
  State<_MiniBadge> createState() => _MiniBadgeState();
}

class _MiniBadgeState extends State<_MiniBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);

    if (widget.animate) {
      _ctrl.forward(from: 0.0);
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _MiniBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If it flips from not-animated -> animated, play pop
    if (!oldWidget.animate && widget.animate) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final b = widget.badge;
    final baseColor = _parseHexColor(b.colorHex) ?? cs.primary;

    return ScaleTransition(
      scale: _scale,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showBadgeDialog(context, b, baseColor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: baseColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFromKey(b.iconKey), size: 14, color: baseColor),
              const SizedBox(width: 6),
              Text(
                b.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: baseColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showBadgeDialog(
    BuildContext context,
    BadgeModel b,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(_iconFromKey(b.iconKey), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          (b.description.trim().isEmpty)
              ? "No description provided."
              : b.description,
          style: const TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  static IconData _iconFromKey(String? key) {
    switch (key) {
      case 'badge_pathfinder':
        return Icons.emoji_events_rounded;
      case 'badge_explorer':
        return Icons.explore_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;
    final r = rating.clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < r ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: (a11y.highContrast ? Colors.black : Colors.amber),
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

class _VenuePhotosCard extends StatefulWidget {
  final VenueModel venue;

  const _VenuePhotosCard({required this.venue});

  @override
  State<_VenuePhotosCard> createState() => _VenuePhotosCardState();
}

class _VenuePhotosCardState extends State<_VenuePhotosCard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repo = VenueRepository();

    return _Card(
      title: 'Photos',
      child: FutureBuilder<List<VenueImageModel>>(
        future: repo.fetchVenueImages(widget.venue.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final images = snapshot.data ?? [];

          if (images.isEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.venue.imageUrl,
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
            );
          }

          if (_selectedIndex >= images.length) {
            _selectedIndex = 0;
          }

          final selectedImage = images[_selectedIndex];
          final mainImageUrl = repo.getVenueImageUrl(selectedImage.imagePath);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    mainImageUrl,
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
              if (images.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final img = images[index];
                      final thumbUrl = repo.getVenueImageUrl(img.imagePath);
                      final isSelected = index == _selectedIndex;

                      return GestureDetector(
                        onTap: () async {
                          final img = images[index];

                          setState(() {
                            _selectedIndex = index;
                          });

                          try {
                            await repo.setPrimaryVenueImage(
                              venueId: widget.venue.id,
                              imageId: img.imageId,
                            );
                          } catch (e) {
                            debugPrint('Error setting primary image: $e');
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              thumbUrl,
                              width: 100,
                              height: 78,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 78,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '${images.length} photo${images.length == 1 ? '' : 's'} available',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a11y.highContrast ? Colors.white : cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a11y.highContrast
              ? Colors.black
              : cs.outline.withValues(alpha: 0.18),
          width: a11y.highContrast ? 2 : 1,
        ),
        boxShadow: a11y.highContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: a11y.highContrast ? Colors.black : cs.onSurface,
            ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: a11y.highContrast ? Colors.black : cs.primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: a11y.highContrast
                  ? Colors.black
                  : cs.onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: a11y.highContrast ? Colors.black : cs.onSurface,
            ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: a11y.highContrast
            ? Colors.white
            : cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: a11y.highContrast
              ? Colors.black
              : cs.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: a11y.highContrast ? Colors.black : cs.primary,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

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
              valueColor: AlwaysStoppedAnimation<Color>(
                (a11y.highContrast ? Colors.black : _scoreColor(score)),
              ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final color = (a11y.highContrast ? Colors.black : _scoreColor(score));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

  // Positive feature tags (adjustable if tag set evolves)
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

  // Negative tags
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
    final theme = Theme.of(context);
    final a11y = context.watch<AccessibilityController>().settings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (a11y.highContrast
            ? Colors.black.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 16,
              color: (a11y.highContrast ? Colors.black : color),
            ),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: (a11y.highContrast ? Colors.black : color),
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

  static String _formattedAddress(VenueModel v) {
    final parts = <String>[
      if ((v.addressLine1 ?? '').trim().isNotEmpty) v.addressLine1!.trim(),
      if ((v.city ?? '').trim().isNotEmpty) v.city!.trim(),
      if ((v.zipCode ?? '').trim().isNotEmpty) v.zipCode!.trim(),
    ];

    if (parts.isEmpty) return '—';
    return parts.join(', ');
  }
}

class ReportDialog extends StatefulWidget {
  final String targetType;
  final dynamic targetId;
  final String reportedUserId;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.reportedUserId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _repo = VenueRepository();
  final _detailsController = TextEditingController();
  String _selectedReason = 'Inappropriate Content';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Inappropriate Content',
    'Spam',
    'Harassment',
    'False Information',
    'Other',
  ];

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      await _repo.reportContent(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason,
        description: _detailsController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted. Thank you.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to submit report: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Report Content"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Why are you reporting this?",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedReason,
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (val) => setState(() => _selectedReason = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Additional details (optional)",
                hintStyle: TextStyle(fontSize: 14),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Submit Report"),
        ),
      ],
    );
  }
}
