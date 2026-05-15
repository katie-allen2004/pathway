import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import '../../data/venue_subscription_service.dart';
import '../widgets/venue_card.dart';
import '../../data/venue_model.dart';
import 'package:pathway/core/widgets/pathway_nav_bar.dart';

class MyVenuesPage extends StatefulWidget {
  const MyVenuesPage({super.key});

  @override
  State<MyVenuesPage> createState() => _MyVenuesPageState();
}

class _MyVenuesPageState extends State<MyVenuesPage> {
  final _service = VenueSubscriptionService();

  List<dynamic> _venues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  // load subscribed venues
  Future<void> _loadVenues() async {
    final data = await _service.getSubscribedVenues();

    setState(() {
      _venues = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'My Venues',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _venues.isEmpty
              ? const Center(
                  child: Text('no subscribed venues'),
                )
              : ListView.builder(
                  itemCount: _venues.length,
                  itemBuilder: (context, index) {
                    final venueJson = _venues[index];

                    final venue = VenueModel.fromJson(venueJson);

                    return VenueCard(
                      venue: venue,
                      isOwner: false,
                      onFavoriteToggle: (_) {
                        // refresh list after favorite changes
                        _loadVenues();
                      },
                    );
                  },
                ),
    );
  }
}