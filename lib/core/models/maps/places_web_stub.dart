// Stubbed web places helpers for non-web platforms.
// On mobile/desktop these functions should never be called.

import 'package:google_maps_flutter/google_maps_flutter.dart';

class WebPlaceSuggestion {
  WebPlaceSuggestion({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

Future<List<WebPlaceSuggestion>> webAutocomplete(
  String query, {
  required LatLng center,
  String? countryCode2,
}) async {
  throw UnsupportedError('webAutocomplete is only available on web');
}

Future<(LatLng, String?)?> webPlaceDetails(String placeId) async {
  throw UnsupportedError('webPlaceDetails is only available on web');
}

Future<String?> webReverseGeocode(LatLng p) async {
  throw UnsupportedError('webReverseGeocode is only available on web');
}
