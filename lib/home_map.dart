import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:search_map_place/search_map_place.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  List<LatLng> polygonLatlngs = List<LatLng>();
  Set<Polygon> _polygons = HashSet<Polygon>();
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );

  int _polygonIdCounter = 1;

  bool isPoly = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                  polygons: _polygons,
                  onTap: (point) {
                    // setState(() {
                    //   print("cacacacacacaca");
                    //   polygonLatlngs.add(point);
                    //   _setPolygon();
                    // });
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: SearchMapPlaceWidget(
                    apiKey: "AIzaSyCC_tfdhLxFI-uUalIWlQBMbb7xeBx5aKU",
                    onSelected: (Place place) async {
                      final geolocation = await place.geolocation;

                      // Will animate the GoogleMap camera, taking us to the selected position with an appropriate zoom
                      // final GoogleMapController controller = await _mapController.future;
                      _mapController.animateCamera(
                          CameraUpdate.newLatLng(geolocation.coordinates));
                      _mapController.animateCamera(
                          CameraUpdate.newLatLngBounds(geolocation.bounds, 0));
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        _mapController.animateCamera(CameraUpdate.newLatLng(
                            new LatLng(_currentPosition.latitude,
                                _currentPosition.longitude)));
                        _mapController.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                _currentPosition.latitude,
                                _currentPosition.longitude,
                              ),
                              zoom: 15.0,
                            ),
                          ),
                        );
                      },
                      label: Text('Ubicación actual'),
                      icon: Icon(Icons.location_searching),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        setState(() {
                          isPoly = !isPoly;
                        });
                      },
                      label: !isPoly ? Text('Polygono') : Text("Activado"),
                      icon: Icon(Icons.linear_scale),
                      backgroundColor: !isPoly ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setPolygon() {
    final String pId = 'polygon_id_$_polygonIdCounter';
    _polygons.add(Polygon(
        polygonId: PolygonId(pId),
        points: polygonLatlngs,
        strokeWidth: 4,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.80)));
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    print(_markerAddress);

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          onTap: () {
            if (isPoly) {
              setState(() {
                polygonLatlngs.add(coord);
                _setPolygon();
              });
            } else {
              showModalBottomSheet(
                  context: context,
                  builder: (builder) {
                    return Container(
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Text("Dirección: " + _markerAddress, style: TextStyle(fontSize: 25)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Text("Latitud: " + coord.latitude.toString(), style: TextStyle(fontSize: 25),),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Text("Longitud: " + coord.longitude.toString(), style: TextStyle(fontSize: 25)),
                          )
                        ],
                      ),
                    );
                  });
            }
          },
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          // infoWindow: InfoWindow(
          //   title: coord.toString(),
          //   snippet: _markerAddress,
          // ),
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        onTap: () {
          print("clicked marker ######################################");
          showModalBottomSheet(
              context: context,
              builder: (builder) {
                return Container(
                  child: Text("sdf"),
                );
              });
        },
        // infoWindow: InfoWindow(
        //   title: _currentPosition.toString(),
        //   snippet: _currentAddress,
        // ),
      ),
    );

    // // move camera
    // _mapController.animateCamera(
    //   CameraUpdate.newCameraPosition(
    //     CameraPosition(
    //       target: LatLng(
    //         _currentPosition.latitude,
    //         _currentPosition.longitude,
    //       ),
    //       zoom: 15.0,
    //     ),
    //   ),
    // );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }
}
