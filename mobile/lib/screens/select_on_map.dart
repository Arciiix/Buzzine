import 'package:buzzine/screens/loading.dart';
import "package:flutter/material.dart";
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class SelectOnMap extends StatefulWidget {
  final LatLng? previousPosition;
  const SelectOnMap({Key? key, this.previousPosition}) : super(key: key);

  @override
  _SelectOnMapState createState() => _SelectOnMapState();
}

class _SelectOnMapState extends State<SelectOnMap> {
  MapController _mapController = MapController();
  bool _isLoading = true;
  LatLng? _selectedPlace;
  LatLng? _userLocation;
  late LatLng _mapCenter;

  @override
  void initState() {
    super.initState();

    _selectedPlace = widget.previousPosition;
    //51, 19 is around Silesian voivodeship in Poland
    _mapCenter = widget.previousPosition ?? LatLng(51, 19);
    getLocation();
  }

  void getLocation() async {
    bool isServiceEnabled;
    LocationPermission permission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      displayError("Włącz lokalizację!");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        displayError("Nie otrzymano wymaganych uprawnień!");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      displayError(
          "Odrzuciłeś uprawnienia na zawsze! Zmień je ręcznie w ustawieniach!");
      return;
    }
    Position userPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(userPosition.latitude, userPosition.longitude);
      _isLoading = false;
      _mapCenter = _userLocation!;
    });
  }

  displayError(String errorDescription) async {
    await showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(title: Text("Błąd"), content: Text(errorDescription)));

    setState(() {
      _isLoading = false;
    });
  }

  void setSelectedPlace(_, LatLng location) {
    setState(() {
      _selectedPlace = location;
    });
  }

  void moveToCurrentLocation() {
    if (_userLocation != null) {
      _mapController.moveAndRotate(_userLocation!, 13, 0);
    }
  }

  void selectLocation() async {
    if (_selectedPlace == null && _userLocation != null) {
      bool? setCurrentLocationAsSelectedPlace = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Wybierz aktualną lokalizację"),
            content: Text(
                'Nie wybrałeś żadnego miejsca na mapie. Czy chcesz ustawić aktualną lokalizację za dom?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Nie"),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Tak")),
            ],
          );
        },
      );
      if (setCurrentLocationAsSelectedPlace == true) {
        Navigator.of(context).pop(_userLocation);
        return;
      } else {
        Navigator.of(context).pop();
        return;
      }
    }
    Navigator.of(context).pop(_selectedPlace);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Wybierz punkt"),
          ),
          body: Loading(
            showText: true,
          ));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wybierz punkt"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: selectLocation,
          ),
        ],
      ),
      floatingActionButton: _userLocation != null
          ? FloatingActionButton(
              onPressed: moveToCurrentLocation,
              child: Icon(Icons.my_location),
            )
          : null,
      body: FlutterMap(
        mapController: _mapController,
        options:
            MapOptions(center: _mapCenter, zoom: 13.0, onTap: setSelectedPlace),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(markers: [
            Marker(
              width: _userLocation != null ? 80.0 : 0,
              height: _userLocation != null ? 80.0 : 0,
              point: _userLocation ??
                  LatLng(0,
                      0), //If the _userLocation variable is null, it will be 0 width and height, so it can show anywhere
              builder: (ctx) =>
                  Icon(Icons.my_location, color: Colors.blueAccent, size: 50),
            ),
            Marker(
              width: _selectedPlace != null ? 80.0 : 0,
              height: _selectedPlace != null ? 80.0 : 0,
              point: _selectedPlace ??
                  LatLng(0,
                      0), //If the _selectedPlace variable is null, it will be 0 width and height, so it can show anywhere
              builder: (ctx) => Container(
                  //The icon anchor point is its center - move it to the top by adding the bottom margin
                  margin: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.location_on,
                      color: Colors.blueAccent, size: 50)),
            )
          ]),
        ],
      ),
    );
  }
}
