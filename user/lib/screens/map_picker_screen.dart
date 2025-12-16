import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  String _address = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _selectedLocation = LatLng(pos.latitude, pos.longitude);
    });

    _controller
        ?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 17));

    await _getAddressFromLatLng(_selectedLocation!);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;

      setState(() {
        _address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      setState(() => _address = "Unknown Location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Location",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          if (_selectedLocation != null)
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _selectedLocation!, zoom: 17),
              onMapCreated: (controller) => _controller = controller,
              markers: {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: _selectedLocation!,
                  draggable: true,
                  onDragEnd: (newPosition) async {
                    setState(() => _selectedLocation = newPosition);
                    await _getAddressFromLatLng(newPosition);
                  },
                ),
              },
              onTap: (newPosition) async {
                setState(() => _selectedLocation = newPosition);
                await _getAddressFromLatLng(newPosition);
              },
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Address display
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _address,
                style: GoogleFonts.poppins(color: AppColors.secondary),
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(
                    context,
                    '$_address (${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})',
                  );
                }
              },
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
