import 'package:flutter/material.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/pages/venue_detail_page.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit; // New callback for Edit
  final VoidCallback onDelete; // New callback for Delete

  const VenueCard({
    super.key,
    required this.venue,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Check if saved; dynamic handles the boolean check from your state
    final bool isSaved = venue.isSaved;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VenueDetailPage(venue: venue)),
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
                  color: Colors.blue.withOpacity(0.1),
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
