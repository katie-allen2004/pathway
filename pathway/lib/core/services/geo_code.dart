import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart'; //latlong2 imports

class GeocodingService {
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.length < 3) return [];

    // this is what we are using, this will users search up their address to autofill coordiantes. 
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'PathwayApp/1.0', 
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Autocomplete error: $e");
    }
    return [];
  }

  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      print("Error during geocoding: $e");
      return null;
    }
  }

  static Future<String?> getAddressFromCoords(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}