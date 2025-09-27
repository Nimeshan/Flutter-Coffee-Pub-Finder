import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });
    _fetchNearbyPlaces(pos.latitude, pos.longitude);
  }

  Future<void> _fetchNearbyPlaces(double lat, double lng) async {
    // Overpass API query (OpenStreetMap free)
    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=[out:json];"
      "node[amenity~'cafe|bar'](around:2000,$lat,$lng);out;",
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    List elements = data["elements"];
    setState(() {
      _markers = elements.map((place) {
        return Marker(
          point: LatLng(place["lat"], place["lon"]),
          width: 40,
          height: 40,
          child: const Icon(Icons.local_cafe, color: Colors.brown, size: 30),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Free Coffee & Pubs Map")),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _userLocation!,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
