import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/services/notification_controller.dart';
import 'package:pathway/models/notification.dart';
import '/features/messaging/presentation/pages/conversations_page.dart';
import '/features/auth/presentation/map_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  bool _isVenuesExpanded = false;
  bool _isReviewsExpanded = false;

  double _minRating = 0.0;
  String? _selectedTag;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Venues",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Minimum Rating: ${_minRating.toStringAsFixed(1)} Stars"),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (val) {
                      setSheetState(() => _minRating = val);
                      setState(() {}); 
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("Accessibility Features"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Wheelchair Accessible',
                      'Accessible Restroom',
                      'Accessible Parking',
                    ].map((tag) {
                      final isSelected = _selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() => _selectedTag = selected ? tag : null);
                          setState(() {}); 
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply Filters"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pathway'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          ElevatedButton(
            onPressed: () {
              InAppNotificationController.instance.show(
                const InAppNotification(
                  title: 'Test',
                  body: 'Live feed updated!',
                ),
              );
            },
            child: const Text('Show notification'),
          )
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
                      'Welcome back, Pathwalker! 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickActionsRow(
                  onFilterPressed: _showFilterSheet, 
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Nearby accessible venues',
                buttonLabel: _isVenuesExpanded ? 'Show less' : 'See all',
                onSeeAll: () {
                  setState(() {
                    _isVenuesExpanded = !_isVenuesExpanded;
                  });
                },
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .schema('pathway')
                  .from('venues_with_scores')
                  .stream(primaryKey: ['venue_id'])
                  .order('created_at', ascending: false), 
              builder: (context, snapshot) {
                if (snapshot.hasError) return SliverToBoxAdapter(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                
                final filteredVenues = snapshot.data!.where((v) {
                  final ratingMatch = (v['avg_rating'] ?? 0.0) >= _minRating;
                  final tagMatch = _selectedTag == null || 
                                   (v['features'] as List).contains(_selectedTag);
                  return ratingMatch && tagMatch;
                }).toList();

                final displayVenues = _isVenuesExpanded ? filteredVenues : filteredVenues.take(3).toList();

                if (displayVenues.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No venues match your filters."),
                    )),
                  );
                }

                return SliverList.builder(
                  itemCount: displayVenues.length,
                  itemBuilder: (context, index) {
                    final v = displayVenues[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _VenueCard(
                        venue: {
                          'name': v['name'] ?? 'Untitled',
                          'city': v['city'] ?? '',
                          'score': (v['avg_rating'] ?? 0.0).toDouble(), 
                          'features': List<String>.from(v['features'] ?? []),
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recent reviews',
                buttonLabel: _isReviewsExpanded ? 'Show less' : 'See all',              
                onSeeAll: () => setState(() => _isReviewsExpanded = !_isReviewsExpanded), 
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .schema('pathway')
                  .from('reviews_with_names') 
                  .stream(primaryKey: ['review_id']) 
                  .order('created_at', ascending: false), 
              builder: (context, snapshot) {
                if (snapshot.hasError) return SliverToBoxAdapter(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                
                final allReviews = snapshot.data!;
                final displayReviews = _isReviewsExpanded ? allReviews : allReviews.take(3).toList();

                return SliverList.builder(
                  itemCount: displayReviews.length,
                  itemBuilder: (context, index) {
                    final data = displayReviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _ReviewCard(
                        review: {
                          'user': data['display_name'] ?? 'Anonymous',
                          'venue': 'Venue #${data['venue_id']}',
                          'rating': (data['rating'] as num?)?.toInt() ?? 0,
                          'text': data['review_text']?.toString() ?? '', 
                        },
                      ),
                    );
                  },
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
  final VoidCallback onFilterPressed;

  const _QuickActionsRow({required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.map_outlined, 
            label: 'Map',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Map...")));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.filter_alt_outlined, 
            label: 'Filters',
            onPressed: onFilterPressed, 
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.chat_bubble_outline, 
            label: 'Messages',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ConversationsPage()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Messages...")));
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon, 
    required this.label, 
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.buttonLabel, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onSeeAll, child: Text(buttonLabel)),
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
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(venue['name'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.accessible_forward, size: 16),
                      const SizedBox(width: 4),
                      Text((venue['score'] as double).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Text(venue['city'] as String, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: (venue['features'] as List<String>)
                  .map((f) => Chip(
                        label: Text(f), 
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      ))
                  .toList(),
            ),
          ],
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
    final theme = Theme.of(context);
    final user = review['user'] as String;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text(user.isNotEmpty ? user[0] : 'U')),
                const SizedBox(width: 8),
                Expanded(child: Text(user, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                    size: 16, color: Colors.amber,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Review of ${review['venue']}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(review['text'] as String, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
/*
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
];*/