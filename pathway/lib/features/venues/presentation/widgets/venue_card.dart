import 'package:flutter/material.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/pages/venue_detail_page.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final bool isOwner;
  final VoidCallback onFavoriteToggle;
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
    // Standardize isSaved to non-nullable for the UI
    final bool isSaved = venue.isSaved;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Navigation logic from version 2
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
            // 1. Image Header (Version 1 Style)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                venue.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.deepPurple.withOpacity(0.05),
                  child: Icon(Icons.image_outlined, 
                    color: Colors.deepPurple.withOpacity(0.2), size: 40),
                ),
              ),
            ),

            // 2. Content Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name ?? 'Unknown Venue',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${venue.addressLine1 ?? ''}${venue.city != null ? ', ${venue.city}' : ''}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildRatingSection(),
                          ],
                        ),
                      ),

                      // 3. Action Buttons
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              color: isSaved ? Colors.red : Colors.grey,
                            ),
                            onPressed: onFavoriteToggle,
                          ),
                          if (isOwner)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit' && onEdit != null) onEdit!();
                                if (value == 'delete' && onDelete != null) onDelete!();
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit, size: 20),
                                    title: Text('Edit'),
                                    dense: true,
                                  ),
                                ),
                                const PopupMenuItem(
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
                    ],
                  ),
                  
                  // 4. Tags (Version 1 Style)
                  if (venue.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: venue.tags.take(3).map((tag) => _buildTag(tag)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    if (venue.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text("NEW • NO REVIEWS",
            style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(venue.averageRating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(" (${venue.totalReviews})",
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
    );
  }
}