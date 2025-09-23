// lib/widgets/inline_map_picker.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:heavy_new/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// A compact inline map + search + draggable marker with "Expand" popup.
/// Writes back to [latCtrl], [lonCtrl], and [addrCtrl] when a location is chosen.
class InlineMapPicker extends StatefulWidget {
  const InlineMapPicker({
    super.key,
    required this.latCtrl,
    required this.lonCtrl,
    required this.addrCtrl,
    required this.googleApiKey, // Places Web API key
    this.initialCenter = const LatLng(31.9539, 35.9106), // Amman fallback
    this.height = 220,
    this.onChanged,
    this.showExpandButton = true,
  });

  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final TextEditingController addrCtrl;
  final String googleApiKey;
  final LatLng initialCenter;
  final double height;
  final VoidCallback? onChanged;
  final bool showExpandButton;

  @override
  State<InlineMapPicker> createState() => _InlineMapPickerState();
}

class _InlineMapPickerState extends State<InlineMapPicker> {
  final Completer<GoogleMapController> _mapCtrl = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

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
    _bootstrap();
    // We will NOT add a listener here; we handle debounce in onChanged directly.
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
        final pos = await Geolocator.getCurrentPosition();
        center = LatLng(pos.latitude, pos.longitude);
      }
      final c = await _mapCtrl.future;
      await c.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _picked = center;
        _locating = false;
      });
      _writeBack(center, keepAddress: true); // don’t overwrite addr yet
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onSearchChanged(String raw) {
    final q = raw.trim();
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchAutocomplete(q);
    });
  }

  Future<void> _fetchAutocomplete(String q) async {
    if (q.isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _loadingPlaces = true);

    final lang = Localizations.localeOf(context).languageCode;

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(q)}'
          '&types=geocode'
          '&language=$lang'
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
        // You can uncomment this to see why (REQUEST_DENIED, OVER_QUERY_LIMIT, etc.)
        // debugPrint('Places Autocomplete status: $status');
        if (mounted) setState(() => _suggestions = []);
      }
    } catch (e) {
      // debugPrint('Places Autocomplete error: $e');
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
      final addr =
          (result?['formatted_address'] as String?) ?? fallbackAddress ?? '';
      final p = LatLng(lat, lng);

      final c = await _mapCtrl.future;
      await c.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
      if (!mounted) return;
      setState(() => _picked = p);
      _writeBack(p, addressOverride: addr);
    }
  }

  void _writeBack(
    LatLng p, {
    bool keepAddress = false,
    String? addressOverride,
  }) {
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
            '&types=geocode'
            '&language=${langFor(ctx)}'
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
          // surface empty so user sees “no results” panel
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
            // rebuild safely via setDlgState instead of markNeedsBuild when possible
            Future<void> safeFetch(String v) async {
              dlgDebounce?.cancel();
              dlgDebounce = Timer(const Duration(milliseconds: 350), () {
                dlgFetchAuto(ctx, v.trim());
              });
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
                              onDragEnd: (p) {
                                setDlgState(() => tempPicked = p);
                              },
                            ),
                        },
                        onTap: (p) => setDlgState(() => tempPicked = p),
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
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: tempPicked == null
                                ? null
                                : () {
                                    setState(() {
                                      _picked = tempPicked;
                                      _writeBack(
                                        _picked!,
                                        addressOverride: tempAddress.isNotEmpty
                                            ? tempAddress
                                            : null,
                                      );
                                    });
                                    Navigator.pop(ctx);
                                  },
                            icon: const Icon(Icons.check),
                            label: Text(ctx.l10n.mapUseThisLocation),
                          ),
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
    final marker = _picked == null
        ? <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('picked'),
              position: _picked!,
              draggable: true,
              onDragEnd: (p) {
                setState(() => _picked = p);
                _writeBack(p);
              },
            ),
          };

    return SizedBox(
      height: widget.height,
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
              onTap: (p) {
                setState(() => _picked = p);
                _writeBack(p);
              },
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
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
                heroTag: 'expand_map_${hashCode}',
                onPressed: _openLargeMapDialog,
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
    // Always render a panel space; if empty show a small "no results" only when the
    // user has typed something (handled by the parent passing empty list vs not).
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: suggestions.isEmpty
            ? ListTile(title: Text(noResultsText), dense: true)
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
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
