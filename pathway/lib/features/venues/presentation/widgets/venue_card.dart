import 'package:flutter/material.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/pages/venue_detail_page.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final bool isOwner;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit; // New callback for Edit
  final VoidCallback onDelete; // New callback for Delete

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
    final bool isSaved = venue.isSaved ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Column(
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              venue.imageUrl, 
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              // empty space handler
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  color: Colors.deepPurple.withOpacity(0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, color: Colors.deepPurple.withOpacity(0.2), size: 40),
                      const SizedBox(height: 8),
                      Text("No image available", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. text info
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
                          
                          // 3. RATING LOGIC (Clean & Conditional)
                          _buildRatingSection(),
                        ],
                      ),
                    ),

                    // buttons
                    Column(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : Colors.grey,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            padding: EdgeInsets.zero,
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
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // tags
                if (venue.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: venue.tags.take(3).map((tagName) => _buildTag(tagName)).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRatingSection() {
    // if no one has rated it yet, we show a clean, subtle label
    if (venue.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "NEW • NO REVIEWS",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // if ratings exist, show the stars
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          venue.averageRating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          " (${venue.totalReviews})",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.deepPurple,
          fontWeight: FontWeight.w600,
    // Check if saved; dynamic handles the boolean check from your state
    final isSaved = venue.isSaved;
    Icon(isSaved ? Icons.favorite : Icons.favorite_border);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
       
        if (venue.id.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("BUG: venue.id is empty (check mapping)"),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VenueDetailPage(venueId: venue.id, initialVenue: venue),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              //  Visual Identifier
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place, color: Colors.blue),
              ),
              const SizedBox(width: 16),

              // Text Details from Database Schema
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name, // name is non-null in your model
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${venue.addressLine1 ?? ''}, ${venue.city ?? 'Location'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Favorite (Heart) Button
              IconButton(
                icon: Icon(
                  venue.isSaved ? Icons.favorite : Icons.favorite_border,
                  color: venue.isSaved ? Colors.red : Colors.grey,
                ),
                onPressed: onFavoriteToggle,
              ),

              // Edit/Delete menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, size: 20),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red, size: 20),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
