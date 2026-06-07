import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    debugPrint('[MapPicker] Starting to determine current position...');

    try {
      if (kIsWeb) {
        debugPrint('[MapPicker] Environment: Web. Fetching browser geolocation...');
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          debugPrint('[MapPicker] Web position fetched: ${position.latitude}, ${position.longitude}');
          setState(() {
            _selectedLocation = LatLng(position.latitude, position.longitude);
            _loading = false;
          });
        }
        return;
      }

      debugPrint('[MapPicker] Environment: Mobile. Checking location services...');
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[MapPicker] Location services are disabled.');
        if (mounted) setState(() => _loading = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      debugPrint('[MapPicker] Current permission status: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('[MapPicker] Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[MapPicker] Location permission denied.');
          if (mounted) setState(() => _loading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[MapPicker] Location permission denied forever.');
        if (mounted) setState(() => _loading = false);
        return;
      }

      debugPrint('[MapPicker] Fetching current GPS position...');
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        debugPrint('[MapPicker] Mobile position fetched: ${position.latitude}, ${position.longitude}');
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[MapPicker] Error while determining position: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'اختر الموقع' : 'Select Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                debugPrint('[MapPicker] Confirming location from App Bar: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(31.5, 34.4667),
                zoom: 13,
              ),
              onMapCreated: (controller) {
                debugPrint('[MapPicker] Google Map successfully created.');
                _mapController = controller;
              },
              onTap: (latLng) {
                debugPrint('[MapPicker] Map tapped at: ${latLng.latitude}, ${latLng.longitude}');
                setState(() {
                  _selectedLocation = latLng;
                });
              },
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                      ),
                    },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedLocation == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                debugPrint('[MapPicker] Confirming location from FAB: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
                Navigator.pop(context, _selectedLocation);
              },
              label: Text(isAr ? 'تأكيد الموقع' : 'Confirm Location'),
              icon: const Icon(Icons.location_on),
            ),
    );
  }
}

class MapViewScreen extends StatelessWidget {
  final LatLng location;
  final String title;

  const MapViewScreen({super.key, required this.location, required this.title});

  Future<void> _openInExternalMap(BuildContext context) async {
    debugPrint('[MapView] Opening external map for: ${location.latitude}, ${location.longitude}');
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[MapView] Failed to open external map.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the map.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: isAr ? 'فتح في خرائط جوجل' : 'Open in Google Maps',
            onPressed: () => _openInExternalMap(context),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 15),
        markers: {
          Marker(markerId: const MarkerId('pharmacy'), position: location),
        },
        myLocationEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }
}
