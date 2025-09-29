// Web-only interop with Google Maps JavaScript API (Places + Geocoder).
// Requires that web/index.html provides a valid API key via
//   <meta name="google_maps_api_key" content="...">
// and loads Maps JS with libraries=places (our template already does this).

// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as jsu;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WebPlaceSuggestion {
  WebPlaceSuggestion({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

Object? _placesService;
Object? _geocoder;

Future<void> _ensureInit() async {
  if (!kIsWeb) return;
  // Wait until google.maps is available
  int attempts = 0;
  while (jsu.getProperty(jsu.getProperty(js.context, 'window'), 'google') ==
          null &&
      attempts < 60) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
  final maps = jsu.getProperty(jsu.getProperty(js.context, 'google'), 'maps');
  if (maps == null) {
    throw StateError('Google Maps JS not available on web');
  }
  _placesService ??= jsu.callConstructor(
    jsu.getProperty(jsu.getProperty(maps, 'places'), 'PlacesService'),
    [jsu.getProperty(js.context, 'document')],
  );
  _geocoder ??= jsu.callConstructor(jsu.getProperty(maps, 'Geocoder'), []);
}

Future<List<WebPlaceSuggestion>> webAutocomplete(
  String query, {
  required LatLng center,
  String? countryCode2,
}) async {
  await _ensureInit();
  final completer = Completer<List<WebPlaceSuggestion>>();
  final maps = jsu.getProperty(jsu.getProperty(js.context, 'google'), 'maps');
  final request = jsu.jsify({
    'input': query,
    if (countryCode2 != null)
      'componentRestrictions': {'country': countryCode2},
    'locationBias': {
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'radius': 50000,
    },
  });

  // Prefer AutocompleteService for lightweight predictions
  final svc = jsu.callConstructor(
    jsu.getProperty(jsu.getProperty(maps, 'places'), 'AutocompleteService'),
    [],
  );
  jsu.callMethod(svc, 'getPlacePredictions', [
    request,
    js.allowInterop((preds, status) {
      final st = status?.toString() ?? '';
      if (st.contains('OK') && preds != null) {
        final list = <WebPlaceSuggestion>[];
        final len = jsu.getProperty(preds, 'length') as int? ?? 0;
        for (var i = 0; i < len; i++) {
          final p = jsu.getProperty(preds, i);
          final description =
              jsu.getProperty(p, 'description')?.toString() ?? '';
          final placeId = jsu.getProperty(p, 'place_id')?.toString() ?? '';
          if (placeId.isNotEmpty) {
            list.add(
              WebPlaceSuggestion(description: description, placeId: placeId),
            );
          }
        }
        completer.complete(list);
      } else {
        completer.complete(<WebPlaceSuggestion>[]);
      }
    }),
  ]);
  return completer.future;
}

Future<(LatLng, String?)?> webPlaceDetails(String placeId) async {
  await _ensureInit();
  final completer = Completer<(LatLng, String?)?>();
  final req = jsu.jsify({
    'placeId': placeId,
    'fields': ['geometry.location', 'formatted_address'],
  });
  jsu.callMethod(_placesService!, 'getDetails', [
    req,
    js.allowInterop((result, status) {
      final st = status?.toString() ?? '';
      if (!st.contains('OK') || result == null) {
        completer.complete(null);
        return;
      }
      final geom = jsu.getProperty(
        jsu.getProperty(result, 'geometry'),
        'location',
      );
      final lat = jsu.callMethod(geom, 'lat', []) as num?;
      final lng = jsu.callMethod(geom, 'lng', []) as num?;
      final addr = jsu.getProperty(result, 'formatted_address')?.toString();
      if (lat != null && lng != null) {
        completer.complete((LatLng(lat.toDouble(), lng.toDouble()), addr));
      } else {
        completer.complete(null);
      }
    }),
  ]);
  return completer.future;
}

Future<String?> webReverseGeocode(LatLng p) async {
  await _ensureInit();
  final completer = Completer<String?>();
  final req = jsu.jsify({
    'location': {'lat': p.latitude, 'lng': p.longitude},
  });
  jsu.callMethod(_geocoder!, 'geocode', [
    req,
    js.allowInterop((results, status) {
      final st = status?.toString() ?? '';
      if (!st.contains('OK') || results == null) {
        completer.complete(null);
        return;
      }
      final len = jsu.getProperty(results, 'length') as int? ?? 0;
      if (len > 0) {
        final first = jsu.getProperty(results, 0);
        final addr = jsu.getProperty(first, 'formatted_address')?.toString();
        completer.complete(addr);
      } else {
        completer.complete(null);
      }
    }),
  ]);
  return completer.future;
}
