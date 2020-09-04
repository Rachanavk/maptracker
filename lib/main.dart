import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_webservice/places.dart';
import 'package:toast/toast.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GoogleMapPlaces(),
    );
  }
}






const apiKey = "AIzaSyD5vvzPN5jyt06dFAqXuGKyd7FpfXFieaU";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: apiKey);

class GoogleMapsServices{
  Future<String> getRouteCoordinates(LatLng l1, LatLng l2)async{
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$apiKey";
    http.Response response = await http.get(url);
    Map values = jsonDecode(response.body);
    print("====================>>>>>>>>${values}");

    return values["routes"][0]["overview_polyline"]["points"];
  }
}

class GoogleMapPlaces extends StatefulWidget {
  @override
  GoogleMapPlacesState createState() => GoogleMapPlacesState();
}

class GoogleMapPlacesState extends State<GoogleMapPlaces> {
  static LatLng latLng;
  final Scaffol_dKey = GlobalKey<ScaffoldState>();
  bool loading = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();

  Set<Polyline> get polyLines => _polyLines;
  Completer<GoogleMapController> _controller = Completer();
  static LatLng latLngDestination;
  double DestinationLat, DestinationLng;
  static LatLng latLngLocation;
  double LocationLat, LocationLng;
  LocationData currentLocation;
  Mode _mode = Mode.overlay;
  BitmapDescriptor DestinationIcon;
  BitmapDescriptor LocationIcon;
  double distanceInMeters;
  String T1 = "Location";
  String T2 = "Destination";



  void onError(PlacesAutocompleteResponse response) {
    Scaffol_dKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handleDestinationButton() async {
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      onError: onError,
      mode: _mode,
    );
    displayDestinationPrediction(p, Scaffol_dKey.currentState);
    if (latLngDestination != null && latLngLocation != null) {
      Route();
    }
  }

  Future<Null> displayDestinationPrediction(Prediction p,
      ScaffoldState scaffold) async {
    if (p != null) {
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(
          p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;
      setState(() {
        T1 = detail.result.name;
      });

      setState(() {
        latLngDestination = LatLng(lat, lng);
        DestinationLat = lat;
        DestinationLng = lng;
      });
      Toast.show(
          "$lat,$lng",
          context
      );
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLngDestination, zoom: 14),
        ),
      );
      _addMarker(latLngDestination, "Dest Marker", "3", DestinationIcon);
    }
  }

  void AddDestinationMarker() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId("111"),
          position: latLngDestination,
          icon: DestinationIcon
      ));
    });
  }


  Future<void> _handleLocationButton() async {
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      onError: onError,
      mode: _mode,
    );
    displayLocationPrediction(p, Scaffol_dKey.currentState);
  }

  Future<Null> displayLocationPrediction(Prediction p,
      ScaffoldState scaffold) async {
    if (p != null) {
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(
          p.placeId);
      final lat = detail.result.geometry.location.lat;
      final lng = detail.result.geometry.location.lng;
      setState(() {
        T2 = detail.result.name;
      });

      setState(() {
        latLngLocation = LatLng(lat, lng);
        LocationLat = lat;
        LocationLng = lng;
      });
      Toast.show(
          "$lat,$lng",
          context
      );
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLngLocation, zoom: 14),
        ),
      );
      _addMarker(latLngLocation, "Loc Marker", "2", LocationIcon);
      if (latLngDestination != null && latLngLocation != null) {
        Route();
      }
    }
  }


  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), 'Images/home.png')
        .then((onValue) {
      DestinationIcon = onValue;
    });

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), 'Images/LocationMarker.png')
        .then((onValue) {
      LocationIcon = onValue;
    });

    super.initState();
  }


  void onCameraMove(CameraPosition position) {
    latLng = position.target;
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  void Route() async {
    String route = await _googleMapsServices.getRouteCoordinates(
        latLngLocation, latLngDestination);
    createRoute(route);
  }

  void createRoute(String encondedPoly) {
    setState(() {
      _polyLines.add(Polyline(
          polylineId: PolylineId(latLng.toString()),
          width: 4,
          points: _convertToLatLng(_decodePoly(encondedPoly)),
          color: Colors.blue));
    });
  }

  void _addMarker(LatLng location, String address, String ID, var Icon) {
    _markers.add(Marker(
        markerId: MarkerId("$ID"),
        position: location,
        infoWindow: InfoWindow(title: address, snippet: "go here"),
        icon: Icon));
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++)
      lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(

        body: Container(
          width: MediaQuery
              .of(context)
              .size
              .width,
          height: MediaQuery
              .of(context)
              .size
              .height,
          child: Stack(
            children: <Widget>[


              GoogleMap(
                polylines: polyLines,
                markers: _markers,
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: new LatLng(34.4054746, 35.8990459),
                  zoom: 14.4746,
                ),
                onCameraMove: onCameraMove,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),


              Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: 100,
                child: SingleChildScrollView(child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 7),
                    GestureDetector(
                        onTap: _handleDestinationButton,
                        child: Container(
                          width: 280,
                          height: 40,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('Images/destination.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 9, right: 50),
                            child: Text(
                              T1,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                    ),
                    SizedBox(height: 5,),
                    GestureDetector(
                        onTap: _handleLocationButton,
                        child: Container(
                          width: 280,
                          height: 40,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('Images/location.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 9, right: 50),
                            child: Text(
                              T2,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                    ),


                  ],
                )
                ),

              ),


            ],
          ),
        ),


      ),
    );
  }
}