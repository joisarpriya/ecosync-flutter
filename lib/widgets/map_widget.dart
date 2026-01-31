import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../state/map_state.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  fm.MapController? _fmController;
  MapState? _attachedState;
  VoidCallback? _mapListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ms = Provider.of<MapState>(context);
    if (_attachedState != ms) {
      if (_attachedState != null && _mapListener != null) {
        try {
          _attachedState!.removeListener(_mapListener!);
        } catch (_) {}
      }
      _attachedState = ms;
      _mapListener = () {
        final sel = _attachedState?.selected;
        if (sel != null) {
          if (kIsWeb && _fmController != null) {
            _fmController!.move(ll.LatLng(sel.lat, sel.lng), 13.5);
          } else if (_controller != null) {
            _controller!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(sel.lat, sel.lng), 13.5));
          }
        }
      };
      _attachedState!.addListener(_mapListener!);
    }
  }

  @override
  void dispose() {
    if (_attachedState != null && _mapListener != null) {
      try {
        _attachedState!.removeListener(_mapListener!);
      } catch (_) {}
    }
    _controller?.dispose();
    _fmController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapState>(context);

    if (kIsWeb) {
      // Web: use FlutterMap (OpenStreetMap) as a reliable fallback for web builds so we avoid the Google JS billing issue.
      _fmController ??= fm.MapController();

      final flMarkers = mapState.locations.map((loc) => fm.Marker(
            point: ll.LatLng(loc.lat, loc.lng),
            width: 44,
            height: 44,
            builder: (ctx) => GestureDetector(
              onTap: () => mapState.select(loc),
              child: Container(
                decoration: BoxDecoration(color: mapState.colorForAqi(loc.aqi), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${loc.aqi}', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: Colors.white)),
              ),
            ),
          )).toList();

      final circles = mapState.locations.map((loc) => fm.CircleMarker(
            point: ll.LatLng(loc.lat, loc.lng),
            color: mapState.colorForAqi(loc.aqi).withOpacity(0.22),
            borderStrokeWidth: 1,
            useRadiusInMeter: true,
            radius: (350 + (loc.aqi * 2)).toDouble(),
          )).toList();

      return fm.FlutterMap(
        mapController: _fmController,
        options: fm.MapOptions(center: ll.LatLng(mapState.selected?.lat ?? 19.0760, mapState.selected?.lng ?? 72.8777), zoom: mapState.selected != null ? 13.0 : 11.0, interactiveFlags: fm.InteractiveFlag.all),
        children: [
          fm.TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'ecosync.app'),
          if (circles.isNotEmpty) fm.CircleLayer(circles: circles),
          if (flMarkers.isNotEmpty) fm.MarkerLayer(markers: flMarkers),
        ],
      );
    }

    // Native platforms: use google_maps_flutter
    final markers = <Marker>{};
    final circles = <Circle>{};

    for (var loc in mapState.locations) {
      final marker = Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.lat, loc.lng),
        infoWindow: InfoWindow(title: '${loc.id.toUpperCase()}', snippet: 'AQI: ${loc.aqi} — ${loc.weather}'),
        onTap: () => mapState.select(loc),
        icon: BitmapDescriptor.defaultMarkerWithHue(mapState.hueForAqi(loc.aqi)),
      );
      markers.add(marker);

      circles.add(Circle(
        circleId: CircleId('${loc.id}_circle'),
        center: LatLng(loc.lat, loc.lng),
        radius: 350 + (loc.aqi * 2), // dynamic spread
        fillColor: mapState.colorForAqi(loc.aqi).withOpacity(0.25),
        strokeColor: mapState.colorForAqi(loc.aqi).withOpacity(0.6),
        strokeWidth: 1,
        consumeTapEvents: false,
      ));
    }

    final start = mapState.selected != null ? CameraPosition(target: LatLng(mapState.selected!.lat, mapState.selected!.lng), zoom: 13.0) : const CameraPosition(target: LatLng(19.0760, 72.8777), zoom: 11.0);

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: start,
      markers: markers,
      circles: circles,
      onMapCreated: (c) => _controller = c,
      myLocationEnabled: false,
    );
  }
}
