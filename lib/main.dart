import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CoffeePubApp());
}

class CoffeePubApp extends StatelessWidget {
  const CoffeePubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    _fetchNearbyPlaces(pos.latitude, pos.longitude);
  }

  Future<void> _fetchNearbyPlaces(double lat, double lng) async {
    const apiKey = "YOUR_API_KEY";
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=2000&type=cafe|bar&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final results = data['results'] as List;

      setState(() {
        _markers = results.map((place) {
          final loc = place['geometry']['location'];
          return Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(loc['lat'], loc['lng']),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['vicinity'],
            ),
          );
        }).toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Coffee & Pubs"),
        backgroundColor: Colors.brown[400],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              markers: _markers,
            ),
    );
  }
}
