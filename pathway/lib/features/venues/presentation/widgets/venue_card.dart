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
    // drives ui
    final bool isSaved = venue.isSaved;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
            // images
            Stack(
              children: [
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
                if (isOwner)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "MY VENUE",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            // content
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
                              venue.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${venue.city ?? 'Unknown City'}${venue.zipCode != null ? ', ${venue.zipCode}' : ''}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildRatingSection(),
                          ],
                        ),
                      ),

                      //action
                      Column(
                        children: [
                          // favorite
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              color: isSaved ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              onFavoriteToggle(venue);
                            },
                          ),
                          const SizedBox(height: 8),
                          // for owner of venue
                          if (isOwner)
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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