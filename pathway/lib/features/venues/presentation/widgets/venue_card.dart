import 'package:flutter/material.dart';
import '../../data/venue_model.dart';
import '../pages/venue_detail_page.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final bool isOwner;
  final Function(VenueModel updatedVenue) onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VenueCard({
    super.key,
    required this.venue,
    required this.isOwner,
    required this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSaved = venue.isSaved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VenueDetailPage(
                  venueId: venue.id,
                  initialVenue: venue,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Image header ----------
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      venue.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.deepPurple.withOpacity(0.05),
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.deepPurple.withOpacity(0.25),
                          size: 44,
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          alignment: Alignment.center,
                          child: const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),

                    // subtle bottom gradient for legibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),

                    // badges (top-left)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          if (isOwner) _PillBadge(text: "MY VENUE"),
                          if (isOwner && isSaved) const SizedBox(width: 8),
                          if (isSaved) _PillBadge(text: "SAVED"),
                        ],
                      ),
                    ),

                    // favorite (top-right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.white.withOpacity(0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: isSaved ? "Unsave" : "Save",
                          iconSize: 22,
                          onPressed: () => onFavoriteToggle(venue),
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Content ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title + menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit' && onEdit != null) onEdit!();
                              if (value == 'delete' && onDelete != null) onDelete!();
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit, size: 20),
                                  title: Text('Edit'),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // location line
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationText(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // rating row
                    _buildRating(),

                    if (venue.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: venue.tags
                            .take(3)
                            .map((tag) => _TagChip(label: tag))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationText() {
    final city = (venue.city ?? '').trim();
    final zip = (venue.zipCode ?? '').trim();

    if (city.isEmpty && zip.isEmpty) return 'Location unknown';
    if (city.isNotEmpty && zip.isNotEmpty) return '$city • $zip';
    return city.isNotEmpty ? city : zip;
  }

  Widget _buildRating() {
    if (venue.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "NEW • NO REVIEWS",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          venue.averageRating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(width: 6),
        Text(
          "(${venue.totalReviews})",
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;
  const _PillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.deepPurple,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}