// Web-only interop with Google Maps JavaScript API (Places + Geocoder).
// Requires that web/index.html provides a valid API key via
//   <meta name="google_maps_api_key" content="...">
// and loads Maps JS with libraries=places (our template already does this).

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// -----------------------------------------------------------------------------
// JS Interop Definitions
// -----------------------------------------------------------------------------

@JS('google.maps.places.AutocompleteService')
extension type AutocompleteService._(JSObject _) implements JSObject {
  external AutocompleteService();
  external void getPlacePredictions(
    AutocompleteRequest request,
    JSFunction callback,
  );
}

@JS('google.maps.places.PlacesService')
extension type PlacesService._(JSObject _) implements JSObject {
  external PlacesService(JSObject divOrMap);
  external void getDetails(PlaceDetailsRequest request, JSFunction callback);
}

@JS('google.maps.Geocoder')
extension type Geocoder._(JSObject _) implements JSObject {
  external Geocoder();
  external void geocode(GeocoderRequest request, JSFunction callback);
}

@JS()
@anonymous
extension type AutocompleteRequest._(JSObject _) implements JSObject {
  external factory AutocompleteRequest({
    String input,
    JSObject? componentRestrictions,
    JSObject? locationBias,
  });
}

@JS()
@anonymous
extension type PlaceDetailsRequest._(JSObject _) implements JSObject {
  external factory PlaceDetailsRequest({
    String placeId,
    JSArray<JSString> fields,
  });
}

@JS()
@anonymous
extension type GeocoderRequest._(JSObject _) implements JSObject {
  external factory GeocoderRequest({
    JSObject location, // {lat: ..., lng: ...}
  });
}

@JS()
@anonymous
extension type AutocompletePrediction._(JSObject _) implements JSObject {
  external String? get description;
  external String? get place_id;
}

@JS()
@anonymous
extension type PlaceResult._(JSObject _) implements JSObject {
  external PlaceGeometry? get geometry;
  external String? get formatted_address;
}

@JS()
@anonymous
extension type PlaceGeometry._(JSObject _) implements JSObject {
  external LatLngLiteral? get location;
}

@JS()
@anonymous
extension type LatLngLiteral._(JSObject _) implements JSObject {
  external num lat();
  external num lng();
}

@JS()
@anonymous
extension type GeocoderResult._(JSObject _) implements JSObject {
  external String? get formatted_address;
}

// -----------------------------------------------------------------------------
// Dart Models
// -----------------------------------------------------------------------------

class WebPlaceSuggestion {
  WebPlaceSuggestion({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

// -----------------------------------------------------------------------------
// Implementation
// -----------------------------------------------------------------------------

PlacesService? _placesService;
Geocoder? _geocoder;

/// Checks if `google.maps` is available in the global context.
bool get _isGoogleMapsLoaded {
  final google = globalContext['google'];
  if (google == null || google.isUndefined || google.isNull) return false;
  final maps = (google as JSObject)['maps'];
  return maps != null && !maps.isUndefined && !maps.isNull;
}

Future<void> _ensureInit() async {
  if (!kIsWeb) return;

  // Wait until google.maps is available
  int attempts = 0;
  while (!_isGoogleMapsLoaded && attempts < 60) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    attempts++;
  }

  if (!_isGoogleMapsLoaded) {
    throw StateError('Google Maps JS not available on web');
  }

  // Initialize services if needed
  if (_placesService == null) {
    // We need a dummy div or map for PlacesService.
    // Usually passing document.createElement('div') works.
    final div =
        (globalContext['document'] as JSObject).callMethod(
              'createElement'.toJS,
              'div'.toJS,
            )
            as JSObject;
    _placesService = PlacesService(div);
  }
  _geocoder ??= Geocoder();
}

Future<List<WebPlaceSuggestion>> webAutocomplete(
  String query, {
  required LatLng center,
  String? countryCode2,
}) async {
  await _ensureInit();
  final completer = Completer<List<WebPlaceSuggestion>>();

  final request = AutocompleteRequest(
    input: query,
    componentRestrictions: countryCode2 != null
        ? {'country': countryCode2.toJS}.jsify() as JSObject
        : null,
    locationBias:
        {
              'center': {
                'lat': center.latitude,
                'lng': center.longitude,
              }.jsify(),
              'radius': 50000,
            }.jsify()
            as JSObject,
  );

  final svc = AutocompleteService();

  svc.getPlacePredictions(
    request,
    (JSArray<AutocompletePrediction>? predictions, JSString? status) {
      final st = status?.toDart ?? '';
      if (st.contains('OK') && predictions != null) {
        final list = <WebPlaceSuggestion>[];
        final dartPreds = predictions.toDart;
        for (final p in dartPreds) {
          final description = p.description ?? '';
          final placeId = p.place_id ?? '';
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
    }.toJS,
  );

  return completer.future;
}

Future<(LatLng, String?)?> webPlaceDetails(String placeId) async {
  await _ensureInit();
  final completer = Completer<(LatLng, String?)?>();

  final request = PlaceDetailsRequest(
    placeId: placeId,
    fields: [
      'geometry.location',
      'formatted_address',
    ].map((e) => e.toJS).toList().toJS,
  );

  _placesService!.getDetails(
    request,
    (PlaceResult? result, JSString? status) {
      final st = status?.toDart ?? '';
      if (!st.contains('OK') || result == null) {
        completer.complete(null);
        return;
      }

      final geom = result.geometry;
      final loc = geom?.location;

      if (loc != null) {
        final lat = loc.lat().toDouble();
        final lng = loc.lng().toDouble();
        final addr = result.formatted_address;
        completer.complete((LatLng(lat, lng), addr));
      } else {
        completer.complete(null);
      }
    }.toJS,
  );

  return completer.future;
}

Future<String?> webReverseGeocode(LatLng p) async {
  await _ensureInit();
  final completer = Completer<String?>();

  final request = GeocoderRequest(
    location: {'lat': p.latitude, 'lng': p.longitude}.jsify() as JSObject,
  );

  _geocoder!.geocode(
    request,
    (JSArray<GeocoderResult>? results, JSString? status) {
      final st = status?.toDart ?? '';
      if (!st.contains('OK') || results == null) {
        completer.complete(null);
        return;
      }

      final dartResults = results.toDart;
      if (dartResults.isNotEmpty) {
        completer.complete(dartResults.first.formatted_address);
      } else {
        completer.complete(null);
      }
    }.toJS,
  );

  return completer.future;
}
