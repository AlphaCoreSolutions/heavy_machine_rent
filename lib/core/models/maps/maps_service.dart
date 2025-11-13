// lib/widgets/inline_map_picker.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:ajjara/l10n/app_localizations.dart';

// Conditional import for web interop
import 'places_web_stub.dart' if (dart.library.html) 'places_web.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// A compact inline map + search + draggable marker with "Expand" popup.
/// Writes back to [latCtrl], [lonCtrl], and [addrCtrl] when a location is chosen.
class InlineMapPicker extends StatefulWidget {
  InlineMapPicker({
    super.key,
    required this.latCtrl,
    required this.lonCtrl,
    required this.addrCtrl,
    required this.googleApiKey, // Places Web API key
    this.initialCenter = const LatLng(31.9539, 35.9106), // Amman fallback
    this.height = 220,
    this.onChanged,
    this.showExpandButton = true,

    // Back-compat / advanced tuning
    this.showSearchDropdown = true,
    this.minSearchChars = 2,
    this.debounceMs = 350,
    this.centerOnSelection = true,
    this.onPlaceSelected,

    // On iOS, embedding GoogleMap inside large scrolls can cause freezes/crashes.
    // Default to a lightweight placeholder inline that opens a dialog map.
    bool? inlineInteractive,
  }) : inlineInteractive =
           inlineInteractive ?? (defaultTargetPlatform != TargetPlatform.iOS);

  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final TextEditingController addrCtrl;
  final String googleApiKey;
  final LatLng initialCenter;
  final double height;
  final VoidCallback? onChanged;
  final bool showExpandButton;
  final bool showSearchDropdown;
  final int minSearchChars;
  final int debounceMs;
  final bool centerOnSelection;
  final ValueChanged<LatLng>? onPlaceSelected;
  // if false (default on iOS), show a non-interactive placeholder inline and open dialog for picking
  final bool inlineInteractive;

  @override
  State<InlineMapPicker> createState() => _InlineMapPickerState();
}

class _InlineMapPickerState extends State<InlineMapPicker> {
  final Completer<GoogleMapController> _mapCtrl = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _lastKnownCenter; // remember where we centered the small map
  String? _centerCountryCode; // country from current center
  bool _writingBack =
      false; // prevent feedback loops when writing to controllers

  bool get _usesInlineMap => widget.inlineInteractive;

  void _attachControllerListeners() {
    widget.latCtrl.addListener(_onExternalCoordsChanged);
    widget.lonCtrl.addListener(_onExternalCoordsChanged);
  }

  void _detachControllerListeners() {
    widget.latCtrl.removeListener(_onExternalCoordsChanged);
    widget.lonCtrl.removeListener(_onExternalCoordsChanged);
  }

  void _onExternalCoordsChanged() async {
    if (_writingBack) return;
    final lat = double.tryParse(widget.latCtrl.text);
    final lon = double.tryParse(widget.lonCtrl.text);
    if (lat == null || lon == null) return;
    final p = LatLng(lat, lon);
    if (_picked != null &&
        (_picked!.latitude == p.latitude &&
            _picked!.longitude == p.longitude)) {
      return;
    }
    setState(() {
      _picked = p;
      _lastKnownCenter = p;
    });
    if (_usesInlineMap) {
      final c = await _mapCtrl.future;
      await c.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
    }
  }

  LatLng _biasCenter() {
    // Prefer the most relevant center we know
    return _picked ?? _lastKnownCenter ?? widget.initialCenter;
  }

  // Places session token (reuse during the user's search session)
  final String _placesSession = const Uuid().v4();

  LatLng? _picked;
  bool _locating = true;
  bool _loadingPlaces = false;
  List<_PlaceSug> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap(); // run after first frame so the map paints immediately
    });
    _attachControllerListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _detachControllerListeners();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _reverseGeocode(LatLng p) async {
    // On web, prefer JS Geocoder to avoid CORS and key restrictions
    if (kIsWeb) {
      try {
        return await webReverseGeocode(p);
      } catch (_) {}
    }
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${p.latitude},${p.longitude}'
          '&language=$lang'
          '&key=${widget.googleApiKey}';
      final r = await http.get(Uri.parse(url));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      if ((j['status'] as String?) == 'OK') {
        final results = (j['results'] as List?) ?? const [];
        if (results.isNotEmpty) {
          return (results.first['formatted_address'] as String?)?.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _countryCodeAt(LatLng p) async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${p.latitude},${p.longitude}'
          '&language=$lang'
          '&key=${widget.googleApiKey}';
      final r = await http.get(Uri.parse(url));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      if ((j['status'] as String?) == 'OK') {
        final results = (j['results'] as List?) ?? const [];
        if (results.isNotEmpty) {
          final comps =
              (results.first['address_components'] as List?) ?? const [];
          for (final c in comps) {
            final types = (c['types'] as List?)?.cast<String>() ?? const [];
            if (types.contains('country')) {
              final shortName = (c['short_name'] as String?)?.trim();
              if (shortName != null && shortName.length == 2) {
                return shortName.toLowerCase();
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _bootstrap() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      LatLng center = widget.initialCenter;
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw 'timeout',
        );
        center = LatLng(pos.latitude, pos.longitude);
      }
      if (_usesInlineMap) {
        final c = await _mapCtrl.future;
        await c.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: center, zoom: 15),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _picked = center;
        _lastKnownCenter = center;
        _locating = false;
      });
      _centerCountryCode = await _countryCodeAt(center);
      _writeBack(center, keepAddress: true); // don’t overwrite addr yet
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onSearchChanged(String raw) {
    final q = raw.trim();
    _debounce?.cancel();
    if (q.length < widget.minSearchChars) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      _fetchAutocomplete(q);
    });
  }

  Future<void> _fetchAutocomplete(String q) async {
    final lang = Localizations.localeOf(context).languageCode;
    final center = _biasCenter();
    final bias = 'circle:50000@${center.latitude},${center.longitude}'; // ~50km
    final comps = (_centerCountryCode != null)
        ? '&components=country:$_centerCountryCode'
        : '';
    if (q.isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _loadingPlaces = true);

    try {
      if (kIsWeb) {
        final preds = await webAutocomplete(
          q,
          center: center,
          countryCode2: _centerCountryCode,
        );
        if (mounted) {
          setState(
            () => _suggestions = preds
                .map(
                  (e) =>
                      _PlaceSug(description: e.description, placeId: e.placeId),
                )
                .toList(),
          );
        }
      } else {
        final url =
            'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(q)}'
            '$comps'
            '&language=$lang'
            '&locationbias=${Uri.encodeComponent(bias)}'
            '&sessiontoken=$_placesSession'
            '&key=${widget.googleApiKey}';

        final r = await http.get(Uri.parse(url));
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final status = (j['status'] as String?) ?? 'UNKNOWN_ERROR';

        if (status == 'OK') {
          final preds = (j['predictions'] as List)
              .map(
                (e) => _PlaceSug(
                  description: (e['description'] ?? '').toString(),
                  placeId: (e['place_id'] ?? '').toString(),
                ),
              )
              .toList();
          if (mounted) setState(() => _suggestions = preds);
        } else {
          if (mounted) setState(() => _suggestions = []);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loadingPlaces = false);
    }
  }

  Future<void> _selectPlace(_PlaceSug s) async {
    setState(() => _suggestions = []);
    _searchCtrl.text = s.description;
    await _moveToPlaceIdAndWriteBack(s.placeId, fallbackAddress: s.description);
  }

  Future<void> _moveToPlaceIdAndWriteBack(
    String placeId, {
    String? fallbackAddress,
  }) async {
    if (kIsWeb) {
      final res = await webPlaceDetails(placeId);
      if (res == null) return;
      final (p, addr) = res;
      if (widget.centerOnSelection && _usesInlineMap) {
        final c = await _mapCtrl.future;
        await c.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
      }
      _lastKnownCenter = p;
      _centerCountryCode = await _countryCodeAt(p);
      if (!mounted) return;
      setState(() => _picked = p);
      _writeBack(p, addressOverride: addr ?? fallbackAddress ?? '');
      widget.onPlaceSelected?.call(p);
      return;
    }

    final lang = Localizations.localeOf(context).languageCode;
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&fields=geometry/location,formatted_address'
        '&language=$lang'
        '&sessiontoken=$_placesSession'
        '&key=${widget.googleApiKey}';
    final r = await http.get(Uri.parse(url));
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final result = j['result'] as Map<String, dynamic>?;

    final loc = result?['geometry']?['location'];
    if (loc is Map) {
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final p = LatLng(lat, lng);
      final addr =
          (result?['formatted_address'] as String?) ?? fallbackAddress ?? '';
      if (widget.centerOnSelection && _usesInlineMap) {
        final c = await _mapCtrl.future;
        await c.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
      }
      _lastKnownCenter = p;
      _centerCountryCode = await _countryCodeAt(p);
      if (!mounted) return;
      setState(() => _picked = p);
      _writeBack(p, addressOverride: addr);
      widget.onPlaceSelected?.call(p);
    }
  }

  void _writeBack(
    LatLng p, {
    bool keepAddress = false,
    String? addressOverride,
  }) {
    _writingBack = true;
    widget.latCtrl.text = p.latitude.toStringAsFixed(7);
    widget.lonCtrl.text = p.longitude.toStringAsFixed(7);
    if (!keepAddress) {
      if (addressOverride != null && addressOverride.isNotEmpty) {
        widget.addrCtrl.text = addressOverride;
      } else if (widget.addrCtrl.text.isEmpty) {
        widget.addrCtrl.text =
            '${context.l10n.mapLatLabel(p.latitude.toStringAsFixed(6))}, '
            '${context.l10n.mapLngLabel(p.longitude.toStringAsFixed(6))}';
      }
    }
    _writingBack = false;
    widget.onChanged?.call();
  }

  Future<void> _openLargeMapDialog() async {
    // Hoist local dialog state OUTSIDE builder so it doesn't reset on rebuild.
    LatLng? tempPicked = _picked;
    String tempAddress = widget.addrCtrl.text;
    final TextEditingController dlgSearch = TextEditingController(
      text: _searchCtrl.text,
    );
    final Completer<GoogleMapController> dlgCtrl = Completer();
    List<_PlaceSug> dlgSuggestions = [];
    bool dlgBusy = false;
    Timer? dlgDebounce;

    String langFor(BuildContext c) => Localizations.localeOf(c).languageCode;

    Future<void> dlgFetchAuto(BuildContext ctx, String q) async {
      final lang = Localizations.localeOf(context).languageCode;
      final center = _biasCenter();
      final bias = 'circle:50000@${center.latitude},${center.longitude}';
      final comps = (_centerCountryCode != null)
          ? '&components=country:$_centerCountryCode'
          : '';
      if (q.isEmpty) {
        dlgSuggestions = [];
        (ctx as Element).markNeedsBuild();
        return;
      }
      dlgBusy = true;
      (ctx as Element).markNeedsBuild();
      try {
        final url =
            'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(q)}'
            '$comps'
            '&language=$lang'
            '&locationbias=${Uri.encodeComponent(bias)}'
            '&sessiontoken=$_placesSession'
            '&key=${widget.googleApiKey}';
        final r = await http.get(Uri.parse(url));
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final status = (j['status'] as String?) ?? 'UNKNOWN_ERROR';
        if (status == 'OK') {
          dlgSuggestions = (j['predictions'] as List)
              .map(
                (e) => _PlaceSug(
                  description: (e['description'] ?? '').toString(),
                  placeId: (e['place_id'] ?? '').toString(),
                ),
              )
              .toList();
        } else {
          dlgSuggestions = [];
        }
      } catch (_) {
        dlgSuggestions = [];
      } finally {
        dlgBusy = false;
        (ctx).markNeedsBuild();
      }
    }

    Future<void> dlgSelect(BuildContext ctx, _PlaceSug s) async {
      dlgSuggestions = [];
      (ctx as Element).markNeedsBuild();
      dlgSearch.text = s.description;

      final url =
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${Uri.encodeComponent(s.placeId)}'
          '&fields=geometry/location,formatted_address'
          '&language=${langFor(ctx)}'
          '&sessiontoken=$_placesSession'
          '&key=${widget.googleApiKey}';
      final r = await http.get(Uri.parse(url));
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final result = j['result'] as Map<String, dynamic>?;

      final loc = result?['geometry']?['location'];
      if (loc is Map) {
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        tempAddress =
            (result?['formatted_address'] as String?) ?? s.description;
        tempPicked = LatLng(lat, lng);

        final c = await dlgCtrl.future;
        await c.animateCamera(CameraUpdate.newLatLngZoom(tempPicked!, 16));
        (ctx).markNeedsBuild();
      }
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            Future<void> safeFetch(String v) async {
              dlgDebounce?.cancel();
              if (v.trim().length < widget.minSearchChars) {
                setDlgState(() => dlgSuggestions = []);
                return;
              }
              dlgDebounce = Timer(
                Duration(milliseconds: widget.debounceMs),
                () {
                  dlgFetchAuto(ctx, v.trim());
                },
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.96,
                height: MediaCore.isWide(context)
                    ? MediaQuery.of(context).size.height * 0.7
                    : MediaQuery.of(context).size.height * 0.75,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: tempPicked ?? _picked ?? widget.initialCenter,
                          zoom: 13,
                        ),
                        onMapCreated: (c) async {
                          dlgCtrl.complete(c);
                          if (tempPicked == null && _picked != null) {
                            await c.moveCamera(
                              CameraUpdate.newLatLngZoom(_picked!, 15),
                            );
                          }
                        },
                        myLocationEnabled: true,
                        zoomControlsEnabled: true,
                        markers: {
                          if (tempPicked != null)
                            Marker(
                              markerId: const MarkerId('dlg'),
                              position: tempPicked!,
                              draggable: true,
                              onDragEnd: (p) async {
                                // update ONLY dialog-local state
                                setDlgState(() {
                                  tempPicked = p;
                                });

                                final c = await dlgCtrl.future;
                                await c.animateCamera(
                                  CameraUpdate.newLatLngZoom(p, 16),
                                );
                              },
                            ),
                        },
                        onTap: (p) async {
                          // FIX: update dialog-local state so the pin appears
                          setDlgState(() {
                            tempPicked = p;
                          });

                          final c = await dlgCtrl.future;
                          await c.animateCamera(
                            CameraUpdate.newLatLngZoom(p, 16),
                          );
                        },
                      ),
                    ),

                    // top search
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: _DialogSearchBox(
                        controller: dlgSearch,
                        busy: dlgBusy,
                        hint: ctx.l10n.mapSearchHint,
                        onChanged: safeFetch,
                        onClear: () {
                          dlgSearch.clear();
                          setDlgState(() => dlgSuggestions = []);
                        },
                      ),
                    ),

                    // suggestions
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 58,
                      child: _SuggestionPanel(
                        suggestions: dlgSuggestions,
                        onSelect: (s) => dlgSelect(ctx, s),
                        noResultsText: ctx.l10n.mapNoResults,
                      ),
                    ),

                    // bottom actions
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(ctx.l10n.mapCancel),
                          ),
                          Expanded(
                            child: Center(
                              child: FilledButton.icon(
                                onPressed: tempPicked == null
                                    ? null
                                    : () async {
                                        // Commit dialog choice back to parent
                                        setState(() {
                                          _picked = tempPicked;
                                        });
                                        _lastKnownCenter = tempPicked;
                                        _centerCountryCode =
                                            await _countryCodeAt(tempPicked!);

                                        // Resolve a friendly address after confirm
                                        final name = await _reverseGeocode(
                                          tempPicked!,
                                        );
                                        _writeBack(
                                          _picked!,
                                          addressOverride:
                                              (name ?? tempAddress).isNotEmpty
                                              ? (name ?? tempAddress)
                                              : null,
                                        );

                                        if (_usesInlineMap) {
                                          final c = await _mapCtrl.future;
                                          await c.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                              _picked!,
                                              16,
                                            ),
                                          );
                                        }
                                        if (mounted) {
                                          Navigator.pop(ctx);
                                        }
                                      },
                                icon: const Icon(Icons.check),
                                label: Text(ctx.l10n.mapUseThisLocation),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // On iOS by default, avoid embedding the platform view inline to prevent scroll freezes.
    if (!widget.inlineInteractive &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      return _InlineMapPlaceholder(
        height: widget.height,
        addressText: widget.addrCtrl.text,
        onOpen: _openLargeMapDialog,
      );
    }
    final marker = _picked == null
        ? <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('picked'),
              position: _picked!,
              draggable: true,
              onDragEnd: (p) async {
                setState(() => _picked = p);
                _lastKnownCenter = p;
                _centerCountryCode = await _countryCodeAt(p);
                _writeBack(p);
              },
            ),
          };

    return SizedBox(
      height: widget.height,
      child: RepaintBoundary(
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialCenter,
                  zoom: 13,
                ),
                onMapCreated: (c) => _mapCtrl.complete(c),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: marker,
                onTap: (p) async {
                  setState(() => _picked = p);
                  _lastKnownCenter = p;
                  _centerCountryCode = await _countryCodeAt(p);

                  final name = await _reverseGeocode(p);
                  _writeBack(p, addressOverride: name);

                  if (_usesInlineMap) {
                    final c = await _mapCtrl.future;
                    await c.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
                  }
                },
                compassEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,

                // ⬇️ Give the map priority for gestures so it doesn’t fight with parent scroll
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),

            // top search (inline)
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: _SearchBox(
                controller: _searchCtrl,
                busy: _loadingPlaces || _locating,
                hint: context.l10n.mapSearchHint,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _suggestions = []);
                },
              ),
            ),

            // suggestions dropdown (inline)
            Positioned(
              left: 8,
              right: 8,
              top: 56,
              child: _SuggestionPanel(
                suggestions: _suggestions,
                onSelect: _selectPlace,
                noResultsText: context.l10n.mapNoResults,
              ),
            ),

            // expand button
            if (widget.showExpandButton)
              Positioned(
                right: 8,
                bottom: 8,
                child: FloatingActionButton.small(
                  heroTag: 'expand_map_$hashCode',
                  onPressed: _openLargeMapDialog,
                  tooltip: context.l10n.mapExpandTooltip,
                  child: const Icon(Icons.open_in_full),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineMapPlaceholder extends StatelessWidget {
  const _InlineMapPlaceholder({
    required this.height,
    required this.addressText,
    required this.onOpen,
  });
  final double height;
  final String addressText;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.map_outlined, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addressText.isEmpty
                        ? context.l10n.mapSearchHint
                        : addressText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'expand_map_placeholder_$hashCode',
              onPressed: onOpen,
              tooltip: context.l10n.mapExpandTooltip,
              child: const Icon(Icons.open_in_full),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.suggestions,
    required this.onSelect,
    required this.noResultsText,
  });

  final List<_PlaceSug> suggestions;
  final ValueChanged<_PlaceSug> onSelect;
  final String noResultsText;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 0, bottom: 14),
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final s = suggestions[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined),
              title: Text(s.description, maxLines: 2),
              onTap: () => onSelect(s),
            );
          },
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.busy,
    required this.onChanged,
    required this.onClear,
    required this.hint,
  });
  final TextEditingController controller;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: busy
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: context.l10n.mapClear,
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    )
                  : null),
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}

class _DialogSearchBox extends StatelessWidget {
  const _DialogSearchBox({
    required this.controller,
    required this.busy,
    required this.onChanged,
    required this.onClear,
    required this.hint,
  });
  final TextEditingController controller;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: busy
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: context.l10n.mapClear,
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    )
                  : null),
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}

class _PlaceSug {
  _PlaceSug({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

/// small helper to detect width (purely aesthetic for dialog height)
class MediaCore {
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 720;
}
