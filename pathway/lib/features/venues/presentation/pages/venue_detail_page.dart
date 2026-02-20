import 'package:flutter/material.dart';
import '../../data/venue_model.dart';

class VenueDetailPage extends StatelessWidget {
  final VenueModel venue;

  const VenueDetailPage({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFE9ECF7);
    const primary = Color(0xFF4754B8);

    final address = [
      if (venue.addressLine1 != null && venue.addressLine1!.trim().isNotEmpty)
        venue.addressLine1!.trim(),
      if (venue.city != null && venue.city!.trim().isNotEmpty) venue.city!.trim(),
    ].join(', ');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Venue Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Title =====
          Text(
            venue.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // ===== Address / City =====
          if (address.isNotEmpty)
            Text(
              address,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            )
          else
            const Text(
              'Address not available',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

          const SizedBox(height: 14),

          // ===== Accessibility Score Badge (placeholder) =====
          Row(
            children: const [
              _Badge(text: 'Accessibility: TBD'),
              SizedBox(width: 10),
              _Badge(text: 'Rating: TBD'),
            ],
          ),

          const SizedBox(height: 16),

          // ===== Tags Row (placeholder) =====
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

          // ===== Photos Section (placeholder) =====
          const Text(
            'Photos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _PlaceholderCard(
            height: 140,
            child: const Center(child: Text('Photos placeholder')),
          ),

          const SizedBox(height: 18),

          // ===== Description =====
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
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 18),

          // ===== Reviews Section (placeholder) =====
          const Text(
            'Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _PlaceholderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top reviews preview (TBD)'),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: null, // enable later
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('See all reviews (coming soon)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
