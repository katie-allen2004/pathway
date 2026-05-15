import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/venue_model.dart';
import '../pages/venue_detail_page.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'subscribe_venue_button.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final bool isSaved = venue.isSaved;
    final bool isHighContrast = a11y.highContrast;
    final bool isDark = theme.brightness == Brightness.dark;

    final cardColor = isHighContrast
        ? Colors.white
        : (isDark? cs.surfaceContainerHighest : cs.surface);

    final cardBorderColor = isHighContrast
        ? Colors.black
        : cs.outline.withValues(alpha: isDark ? 0.45 : 0.18);

    final titleColor = isHighContrast ? Colors.black : cs.onSurface;
    final subtitleColor = isHighContrast 
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.72);

    final chipBg = isHighContrast 
        ? Colors.white
        : cs.primary.withValues(alpha: isDark ? 0.18 : 0.08);

    final chipBorder = isHighContrast
        ? Colors.black
        : cs.primary.withValues(alpha: isDark ? 0.45 : 0.18);

    final chipText = isHighContrast ? Colors.black : cs.primary;

    final favoriteButtonBg = isHighContrast
        ? Colors.white
        : cs.surface.withValues(alpha: 0.95);
    
    final imagePlaceholderBg = isHighContrast
        ? Colors.white
        : cs.surface.withValues(alpha: 0.06);

    final imagePlaceholderFg = isHighContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: cardColor,
        elevation: isHighContrast ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: cardBorderColor,
            width: isHighContrast ? 2 : 1,
          ),
        ),
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
                        color: imagePlaceholderBg,
                        child: Icon(
                          Icons.image_outlined,
                          color: imagePlaceholderFg,
                          size: 44,
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isHighContrast
                              ? Colors.white
                              : cs.surfaceContainerHighest,
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
                            Colors.black.withValues(
                              alpha: isHighContrast ? 0.55 : 0.35,
                            ),
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
                        color: favoriteButtonBg,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: isSaved ? "Unsave" : "Save",
                          iconSize: 22,
                          onPressed: () => onFavoriteToggle(venue),
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? cs.error : (isHighContrast ? Colors.black : cs.onSurface),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert, color: isHighContrast ? Colors.black : subtitleColor),
                            onSelected: (value) {
                              if (value == 'edit' && onEdit != null) onEdit!();
                              if (value == 'delete' && onDelete != null) onDelete!();
                            },
                            itemBuilder: (context) =>  [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.edit, 
                                    size: 20,
                                    color: isHighContrast
                                      ? Colors.black
                                      : cs.onSurface,
                                    ),
                                  title: Text(
                                    'Edit',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isHighContrast
                                        ? Colors.black
                                        : cs.onSurface,
                                    )),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: cs.error, size: 20),
                                  title: Text('Delete', style: theme.textTheme.bodyMedium?.copyWith(color: cs.error,),),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // subscribe/unsubscribe button
                    SubscribeVenueButton(
                      venueId: venue.id.toString(),
                    ),

                    const SizedBox(height: 6),

                    // location line
                    Row(
                      children: [
                        Icon(Icons.location_on, 
                          size: 16, 
                          color: isHighContrast ? Colors.black : subtitleColor,
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationText(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: a11y.boldText ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // rating row
                    _buildRating(context),

                    if (venue.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: venue.tags
                            .take(3)
                            .map((tag) => _TagChip(
                              label: tag,
                              backgroundColor: chipBg,
                              borderColor: chipBorder,
                              textColor: chipText,
                              ))
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

  Widget _buildRating(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final isHighContrast = a11y.highContrast;
    final isDark = theme.brightness == Brightness.dark;

    if (venue.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighContrast
              ? Colors.white
              : (isDark 
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerHighest.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighContrast
                ? Colors.black
                : cs.outline.withValues(alpha: 0.2),
            width: isHighContrast ? 1.5 : 1,
          ),
        ),
        child: Text(
          "NEW • NO REVIEWS",
          style: theme.textTheme.labelSmall?.copyWith(
            color: isHighContrast 
                ? Colors.black
                : cs.onSurface.withValues(alpha: 0.8),
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "(${venue.totalReviews})",
          style: theme.textTheme.bodySmall?.copyWith(
            color: isHighContrast
                ? Colors.black
                : cs.onSurface.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}