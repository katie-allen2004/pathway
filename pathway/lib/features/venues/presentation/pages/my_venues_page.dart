import 'package:flutter/material.dart';
import '../../data/venue_subscription_service.dart';
import '../widgets/venue_card.dart';
import '../../data/venue_model.dart';

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
      appBar: AppBar(
        title: const Text('my venues'),
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