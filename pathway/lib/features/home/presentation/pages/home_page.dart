import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pathway'), // Title text (upper left corner)
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search), // Search icon (upper right corner)
            onPressed: () {
              // TODO: navigate to map/search page
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, User!', // Opening text 
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18), // Location icon
                        const SizedBox(width: 4),
                        Text(
                          'Nearby venues around you',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick actions row
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _QuickActionsRow(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Nearby venues section
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Nearby accessible venues',
                onSeeAll: () {
                  // TODO: navigate to full venues list / map
                },
              ),
            ),
            SliverList.builder(
              itemCount: _dummyVenues.length,
              itemBuilder: (context, index) {
                final venue = _dummyVenues[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _VenueCard(venue: venue),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Recent reviews section
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recent reviews',
                onSeeAll: () {
                  // TODO: navigate to reviews list
                },
              ),
            ),
            SliverList.builder(
              itemCount: _dummyReviews.length,
              itemBuilder: (context, index) {
                final review = _dummyReviews[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _ReviewCard(review: review),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.map_outlined,
            label: 'Map',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.filter_alt_outlined,
            label: 'Filters',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () {
        // TODO: hook into navigation for each action
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Map<String, Object> venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final name = venue['name'] as String;
    final city = venue['city'] as String;
    final score = venue['score'] as double;
    final features = venue['features'] as List<String>;

    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: navigate to venue detail
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + score row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.accessible_forward, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          score.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                city,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: -4,
                children: features
                    .map(
                      (f) => Chip(
                        label: Text(f),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, Object> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review['user'] as String;
    final venue = review['venue'] as String;
    final text = review['text'] as String;
    final rating = review['rating'] as int;

    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User + rating row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(user[0]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating
                          ? Icons.star
                          : Icons.star_border_outlined,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Review of $venue',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- dummy data just to make the UI feel real for now ---

final List<Map<String, Object>> _dummyVenues = [
  {
    'name': 'Bluebird Cafe',
    'city': 'Albuquerque, NM',
    'score': 4.5,
    'features': ['Ramp', 'Accessible restroom', 'Wide entrance'],
  },
  {
    'name': 'Downtown Library',
    'city': 'Albuquerque, NM',
    'score': 4.8,
    'features': ['Elevator', 'Braille signs', 'Quiet space'],
  },
  {
    'name': 'Sunset Theater',
    'city': 'Albuquerque, NM',
    'score': 4.1,
    'features': ['Reserved seating', 'Assistive listening', 'Ramp'],
  },
];

final List<Map<String, Object>> _dummyReviews = [
  {
    'user': 'Alex',
    'venue': 'Bluebird Cafe',
    'rating': 5,
    'text':
        'Great ramp access and friendly staff. Tables are spaced out enough for my wheelchair.',
  },
  {
    'user': 'Jordan',
    'venue': 'Downtown Library',
    'rating': 4,
    'text':
        'Elevator is a bit slow but everything is clearly labeled and easy to navigate.',
  },
];