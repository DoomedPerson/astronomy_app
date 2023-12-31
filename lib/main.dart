import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'jo7implementation.dart';
import 'astronomical_calculations.dart';
import 'package:flutter/gestures.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

void main() {
  List<List<List<double>>> planetPositions = calculatePlanetPositions();
  runApp(MyApp(planetPositions));
}

int selectedPlanet = -1;
List<double> selectedPlanetInfo = [
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
]; // right asc, dec, azimuth, altitude

List<double> e = [0.2518378778576892, 0.0789125317658808, 0.967, 0.9999294152687143];
List<double> a = [39.58862938517124, 2.767254360873952, 17.92781773504386, 78.68293963959538];
List<double> m = [degreesToRadians(38.68366347318184), degreesToRadians(60.0787728227207), degreesToRadians(274.1404919498392), degreesToRadians(359.9858617465071)];
List<double> inc = [degreesToRadians(17.14771140999114), degreesToRadians(10.5868796009696), degreesToRadians(162.1878711908339), degreesToRadians(134.3558107377023)];
List<double> longnode = [degreesToRadians(110.2923840543057), degreesToRadians(80.25497772273573), degreesToRadians(59.11448293673941), degreesToRadians(326.3691470244605)];
List<double> argp = [degreesToRadians(113.7090015158565), degreesToRadians(73.42179714001003), degreesToRadians(112.257792004868), degreesToRadians(53.50921241435645)];
List<double> timeSets = [2457588.5, 2460200.5, 2439857.5, 2455901.5];
List<double> orbitTimes = [90981.71647718345, 1681.403889244621, 27726.15004984154, 254929.0293747837];


List<String> planetNames = [
  "Sun",
  "Mercury",
  "Venus",
  "Earth",
  "Mars",
  "Jupiter",
  "Saturn",
  "Uranus",
  "Neptune",
  "Moon",
  "Pluto",
  "Ceres",
  "Halleys Comet",
  "2011 Lovejoy"
];

double earthPosAngle = 0;

String moonPhaseAddress = "assets/images/fullMoon";

String planet = '';

Position currentPos = Position(
  latitude: 0.0,
  longitude: 0.0,
  accuracy: 0.0, // Provide the actual accuracy value
  altitude: 0.0, // Provide the actual altitude value
  heading: 0.0, // Provide the actual heading value
  speed: 0.0, // Provide the actual speed value
  speedAccuracy: 0.0, // Provide the actual speedAccuracy value
  timestamp: DateTime.now(), // Provide the actual timestamp value
);

List<StreamSubscription<dynamic>> _streamSubscriptions =
    <StreamSubscription<dynamic>>[];

class MyApp extends StatelessWidget {
  List<List<List<double>>> planetPositions;

  MyApp(this.planetPositions);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 7, 7, 20)),
        scaffoldBackgroundColor: Color.fromARGB(255, 5, 5, 15),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'My Solar System',
        planetPositions: planetPositions, // Pass planetPositions
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<List<List<double>>> planetPositions;

  const MyHomePage({
    Key? key,
    required this.title,
    required this.planetPositions, // Add this line to accept planetPositions
  }) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<void> getPerms() async {
  if (await Permission.location.serviceStatus.isEnabled) {
    var status = await Permission.location.status;
    if (status.isGranted) {
    } else {
      Map<Permission, PermissionStatus> status = await [
        Permission.location,
      ].request();
    }
  } else {
    if (await Permission.location.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}

List<List<List<double>>> calculatePlanetPositions() {
  final yearLengths = {
    88 / 60,
    225 / 60,
    365 / 60,
    687 / 60,
    4333 / 60,
    10756 / 60,
    30687 / 60,
    60190 / 60,
    1,
    orbitTimes[0]/60,
    orbitTimes[1]/60,
    orbitTimes[2]/360,
    orbitTimes[3]/360,
  };
  List<List<List<double>>> positions = [];

  DateTime time = DateTime.now().toUtc();
  double currentJD = JulianDate.gregorianDateToJulianDate(
      time.year, time.month, time.day, time.hour, time.minute, time.second);

  double newmoon = JulianDate.gregorianDateToJulianDate(2000, 1, 6, 18, 14, 0);

  moonPhaseAddress = moonPhase(newmoon, currentJD);

  double t = jd2et(currentJD);
  double upLim = 61;



  double setJD = currentJD;

  for (int i = 0; i < 13; i++) {
    int length = yearLengths.elementAt(i).toInt();
    List<List<double>> planetPositionsForYear = [];

    if (i == 8) {
      upLim = 62 * 2;
      currentJD -= 62;
    }
    
    if (i >= 11)
    {
      upLim = 361;
    }


    for (int j = 0; j < upLim; j++) {
      double t = jd2et(currentJD + yearLengths.elementAt(i) * j);
      List<double> temp = [0, 0, 0];

      switch (i) {
        case 0:
          temp = Vsop87aMicro.getMercury(t);
          break;
        case 1:
          temp = Vsop87aMicro.getVenus(t);
          break;
        case 2:
          temp = Vsop87aMicro.getEarth(t);
          break;
        case 3:
          temp = Vsop87aMicro.getMars(t);
          break;
        case 4:
          temp = Vsop87aMicro.getJupiter(t);
          break;
        case 5:
          temp = Vsop87aMicro.getSaturn(t);
          break;
        case 6:
          temp = Vsop87aMicro.getUranus(t);
          break;
        case 7:
          temp = Vsop87aMicro.getNeptune(t);
          break;
        case >= 9:
          temp = plotEllipse(a[i-9], e[i-9], inc[i-9], argp[i-9], longnode[i-9], m[i-9], timeSets[i-9], currentJD+ yearLengths.elementAt(i)*j, orbitTimes[i-9]);
          break;
        case 8:
          temp = Vsop87aMicro.getEmb(t);

          List<double> earthTemp = Vsop87aMicro.getEarth(t);

          temp[0] = earthTemp[0] + ((temp[0] - earthTemp[0]) * 4700.6776987);

          temp[1] = earthTemp[1] + ((temp[1] - earthTemp[1]) * 4700.6776987);

          break;
        default:
          break;
      }

      planetPositionsForYear.add([temp[0], temp[1]]);
    }

    positions.add(planetPositionsForYear);
  }

  return positions;
}



planetInformation(List<List<double>> coord, double JD) {
  double sunDistance = 0;
  double earthDistance = 0;
  double lightSeconds = 0;

  if (selectedPlanet > 0) {

    List<double> planetCoords = coord[selectedPlanet - 1];

    //List<double>

    List<double> cartesianI = eclipticToCartesianCoordinates(
        planetCoords[2], planetCoords[0], planetCoords[1]);

    List<double> earthCoords = coord[2];
    List<double> cartesianE = eclipticToCartesianCoordinates(
        earthCoords[2], earthCoords[0], earthCoords[1]);

    sunDistance = planetCoords[2];
    earthDistance = calculateDistance(cartesianI[0], cartesianI[1],
        cartesianI[2], cartesianE[0], cartesianE[1], cartesianE[2]);

    lightSeconds = (earthDistance / 0.0020040);
  }
  if (selectedPlanet == 0) {
    sunDistance = 0;
    earthDistance = coord[2][2];

    lightSeconds = (earthDistance / 0.0020040);
  }

  List<double> info = riseSetInfo(selectedPlanet, JD, currentPos);
  if (selectedPlanet != 3) {
    selectedPlanetInfo[0] = info.elementAt(3); // azimuth
    selectedPlanetInfo[1] = info.elementAt(4); // altitude
    selectedPlanetInfo[5] = (info.elementAt(0) - 7) % 24; // trans
    selectedPlanetInfo[6] = (info.elementAt(1) - 7) % 24; // rise
    selectedPlanetInfo[7] = (info.elementAt(2) - 7) % 24; // set
  } else {
    selectedPlanetInfo[0] = 0; // azimuth
    selectedPlanetInfo[1] = 0; // altitude
    selectedPlanetInfo[5] = 0; // trans
    selectedPlanetInfo[6] = 0; // rise
    selectedPlanetInfo[7] = 0; // set
  }


  selectedPlanetInfo[2] = sunDistance; // sun dist
  selectedPlanetInfo[3] = earthDistance; // earth dist
  selectedPlanetInfo[4] = lightSeconds; // light seconds



  
}

Future<Position> getCurrentPosition() async {
  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

void fetchData() async {
  try {
    currentPos = await getCurrentPosition();
    // Use currentPos for further processing
    // ...
  } catch (e) {
    // Handle errors
    print('Error getting position: $e');
  }
}

double calculatePitch(List<double> accelerometerValues) {
  double x = accelerometerValues[0];
  double y = accelerometerValues[1];
  double z = accelerometerValues[2];

  double pitch = atan2(y, sqrt(x * x + z * z));
  return pitch;
}

class _MyHomePageState extends State<MyHomePage> {
  double _currentJD = 0;
  Timer? _timer;
  Timer? _timer2;
  String _currentGregorian =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  // x, y, z
  List<double> mercuryTemp = [0, 0, 0];
  List<double> venusTemp = [0, 0, 0];
  List<double> earthTemp = [0, 0, 0];
  List<double> marsTemp = [0, 0, 0];

  List<double> jupiterTemp = [0, 0, 0];
  List<double> saturnTemp = [0, 0, 0];
  List<double> uranusTemp = [0, 0, 0];
  List<double> neptuneTemp = [0, 0, 0];

  List<double> plutoTemp = [0, 0, 0];
  List<double> ceresTemp = [0, 0, 0];


  List<double> halleysTemp = [0, 0, 0];
  List<double> lovejoy11Temp = [0, 0, 0];

  List<double> moonTemp = [0, 0, 0];

  // longitude, latitude, radius, right-ascension, declination
  List<List<double>> coordinates = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ];

  bool _hasPermissions = false;

  List<double> info = [0, 0, 0];

  double distanceFromSun = 0.0;
  double distanceFromEarth = 0.0;
  String lightDistance = '';

  double transit = 0;
  double set = 0;
  double rise = 0;

  double _header = 0.0;
  double _pitch = 0.0;

  bool guidingMode = false; // Variable to track guiding mode

  double azimuthDifference = 0.0;
  double altitudeDifference = 0.0;

  // Update device orientation based on sensor data
  Future<void> _initCompass() async {
    FlutterCompass.events?.listen((event) {
      if (event?.heading != null) {
        setState(() {
          _header = event.heading!;
        });
      }
    });
  }

  Widget buildArrow(double azimuthDifference) {
    _header %= 360;

    double off = 270;

    azimuthDifference = _header - (selectedPlanetInfo[0]);
    if (selectedPlanet == 3) {
      azimuthDifference = _header;
    }

    double screenHeight = MediaQuery.of(context).size.height;
    // Rotate the arrow based on azimuth difference
    return Container(
      padding: EdgeInsets.only(
          top: screenHeight * .6), // Add top padding of 36 pixels
      child: Transform.rotate(
        angle: (off - azimuthDifference) * (pi / 180),
        child: Icon(
          Icons.arrow_forward,
          size: 60.0,
          color: Colors.red, // Adjust color as needed
        ),
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  @override
  void initState() {
    _updateJD();
    _updatePosition();
    getPerms();

    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateJD();
    });

    _timer2 = Timer.periodic(Duration(seconds: 60), (timer) {
      _updatePosition();
    });

    _initCompass();

    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        List<double> _accelerometerValues = <double>[event.x, event.y, event.z];
        _pitch = calculatePitch(_accelerometerValues) * (180 / pi);
        altitudeDifference = selectedPlanetInfo[1] - _pitch;
      });
    }));
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _timer2?.cancel();
    super.dispose();
  }

  void _updateJD([bool init = false]) {
    setState(() {
      DateTime time = DateTime.now().toUtc();

      _currentJD = JulianDate.gregorianDateToJulianDate(
          time.year, time.month, time.day, time.hour, time.minute, time.second);


      if (init) {
        _updatePosition();
      }

      _currentGregorian = _currentGregorian =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(time.toLocal());
    });

    fetchData();

    planetInformation(coordinates, _currentJD);

    distanceFromSun = selectedPlanetInfo[2];
    distanceFromEarth = selectedPlanetInfo[3];
    lightDistance =
        convertSecondsToHoursMinutesSeconds(selectedPlanetInfo[4].toInt());

    transit = selectedPlanetInfo[5];
    rise = selectedPlanetInfo[6];
    set = selectedPlanetInfo[7];

    if (selectedPlanet >= 0) {
      planet = planetNames[selectedPlanet];
    }
  }

  void _updatePosition() {
    double t = jd2et(_currentJD);

    mercuryTemp = Vsop87aMicro.getMercury(t);
    venusTemp = Vsop87aMicro.getVenus(t);
    earthTemp = Vsop87aMicro.getEarth(t);

    print("merc " + mercuryTemp.toString());
    print("venus" + venusTemp.toString());
    print("earth" + earthTemp.toString());

    marsTemp = Vsop87aMicro.getMars(t);

    jupiterTemp = Vsop87aMicro.getJupiter(t);
    saturnTemp = Vsop87aMicro.getSaturn(t);
    uranusTemp = Vsop87aMicro.getUranus(t);
    neptuneTemp = Vsop87aMicro.getNeptune(t);


    print("mars " + marsTemp.toString());
    print("jup" + jupiterTemp.toString());
    print("saturn" + saturnTemp.toString());

    moonTemp = Vsop87aMicro.getEmb(t);

    moonTemp[0] = ((moonTemp[0] - earthTemp[0]) * 84.6776987);
    moonTemp[1] = ((moonTemp[1] - earthTemp[1]) * 84.6776987);
    moonTemp[2] = ((moonTemp[2] - earthTemp[2]) * 84.6776987);

    coordinates[0] = geocartesianToEclipticCoordinates(
        mercuryTemp[0], mercuryTemp[1], mercuryTemp[2]);
    coordinates[1] = geocartesianToEclipticCoordinates(
        venusTemp[0], venusTemp[1], venusTemp[2]);
    coordinates[2] = geocartesianToEclipticCoordinates(
        earthTemp[0], earthTemp[1], earthTemp[2]);
    coordinates[3] = geocartesianToEclipticCoordinates(
        marsTemp[0], marsTemp[1], marsTemp[2]);

    coordinates[4] = geocartesianToEclipticCoordinates(
        jupiterTemp[0], jupiterTemp[1], jupiterTemp[2]);
    coordinates[5] = geocartesianToEclipticCoordinates(
        saturnTemp[0], saturnTemp[1], saturnTemp[2]);
    coordinates[6] = geocartesianToEclipticCoordinates(
        uranusTemp[0], uranusTemp[1], uranusTemp[2]);
    coordinates[7] = geocartesianToEclipticCoordinates(
        neptuneTemp[0], neptuneTemp[1], neptuneTemp[2]);

    coordinates[8] = geocartesianToEclipticCoordinates(
        moonTemp[0], moonTemp[1], moonTemp[2]);

    plutoTemp = getPlanetRA(a[0], e[0], inc[0], argp[0], longnode[0], m[0], timeSets[0], _currentJD, orbitTimes[0]);

    ceresTemp = getPlanetRA(a[1], e[1], inc[1], argp[1], longnode[1], m[1], timeSets[1], _currentJD, orbitTimes[1]);

    halleysTemp = getPlanetRA(a[2], e[2], inc[2], argp[2], longnode[2], m[2], timeSets[2], _currentJD, orbitTimes[2]);

    lovejoy11Temp = getPlanetRA(a[3], e[3], inc[3], argp[3], longnode[3], m[3], timeSets[3], _currentJD, orbitTimes[3]);


    coordinates[9] = geocartesianToEclipticCoordinates(plutoTemp[0], plutoTemp[1], plutoTemp[2]);

    coordinates[10] = geocartesianToEclipticCoordinates(ceresTemp[0], ceresTemp[1], ceresTemp[2]);

    coordinates[11] = geocartesianToEclipticCoordinates(halleysTemp[0], halleysTemp[1], halleysTemp[2]);

    coordinates[12] = geocartesianToEclipticCoordinates(lovejoy11Temp[0], lovejoy11Temp[1], lovejoy11Temp[2]);


    fetchData();

    planetInformation(coordinates, _currentJD);

    distanceFromSun = selectedPlanetInfo[2];
    distanceFromEarth = selectedPlanetInfo[3];
    lightDistance =
        convertSecondsToHoursMinutesSeconds(selectedPlanetInfo[4].toInt());

    transit = selectedPlanetInfo[5];
    rise = selectedPlanetInfo[6];
    set = selectedPlanetInfo[7];

    if (selectedPlanet >= 0) {
      planet = planetNames[selectedPlanet];
    }

    earthPosAngle = earthOrientation(currentPos.longitude, _currentJD);

  }

  String formatWithLeadingZeros(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  @override
  Widget build(BuildContext context) {
    Color lineColor = altitudeDifference.abs() < 5
        ? Color.fromARGB(255, 200, 100, 100)
        : Color.fromARGB(255, 100, 100, 255);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(4, 5, 5, 1),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        child: Stack(
          children: [
            // Solar System UI
            SolarSystem(
              earthCoordinates: earthTemp,
              mercuryCoordinates: mercuryTemp,
              venusCoordinates: venusTemp,
              marsCoordinates: marsTemp,
              jupiterCoordinates: jupiterTemp,
              saturnCoordinates: saturnTemp,
              uranusCoordinates: uranusTemp,
              neptuneCoordinates: neptuneTemp,
              moonCoordinates: moonTemp,
              planetPositions: widget.planetPositions,
              plutoCoordinates: plutoTemp,
              ceresCoordinates: ceresTemp,
              halleysCoordinates: halleysTemp,
              lovejoy11Coordinates: lovejoy11Temp,
            ),
            if (selectedPlanet >= 0)

              // Text widgets
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _currentGregorian,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 105, 105, 105),
                      ),
                    ),
                    Text(
                      _currentJD.toStringAsFixed(5),
                      style: TextStyle(
                        color: const Color.fromARGB(255, 105, 105, 105),
                      ),
                    ),
                    Text(
                      '$planet',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 105, 105, 105),
                      ),
                    ),
                    if (selectedPlanet != 0)
                      Text(
                        'Distance From Sun: ' +
                            distanceFromSun.toStringAsFixed(5),
                        style: TextStyle(
                          color: const Color.fromARGB(255, 105, 105, 105),
                        ),
                      ),

                    if (selectedPlanet != 3)
                      Text(
                        'Distance From Earth: ' +
                            distanceFromEarth.toStringAsFixed(5) +
                            '\nLight Hours From Earth: ' +
                            lightDistance,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 105, 105, 105),
                        ),
                      ),
                    if (selectedPlanet != 3)
                      Text(
                        'TRANSIT: ' +
                            (transit.floor()).toString() +
                            ':' +
                            formatTimeWithLeadingZeros(
                                ((transit - transit.floor()) * 60).floor()) +
                            '\n RISE: ' +
                            (rise.floor()).toString() +
                            ':' +
                            formatTimeWithLeadingZeros(
                                ((rise - rise.floor()) * 60).floor()) +
                            '\n SET: ' +
                            (set.floor()).toString() +
                            ':' +
                            formatTimeWithLeadingZeros(
                                ((set - set.floor()) * 60).floor()),
                        style: TextStyle(
                          color: const Color.fromARGB(255, 105, 105, 105),
                        ),
                      ),

                    // HERE GOES DATA ON THE PLANET
                  ],
                ),
              ),

            if (selectedPlanet < 0)

              // Text widgets
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        _currentGregorian,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 105, 105, 105),
                        ),
                      ),
                      Text(
                        '$_currentJD',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 105, 105, 105),
                        ),
                      ),
                    ]),
              ),

            if (guidingMode)
              Center(
                child: buildArrow(azimuthDifference),
              ),

            // Vertical bar indicating altitude difference
            if (guidingMode)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 12.0,
                  height: altitudeDifference.abs() * 2,
                  color: lineColor, // Adjust color as needed
                ),
              ),

            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      guidingMode = !guidingMode;
                    });
                  },
                  backgroundColor:
                      Color.fromRGBO(255, 255, 255, 0), // Background color
                  child: Icon(
                    guidingMode ? Icons.close : Icons.navigation,
                    color: Colors.white, // Icon color
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SolarSystem extends StatefulWidget {
  final List<double> earthCoordinates;
  final List<double> mercuryCoordinates;
  final List<double> venusCoordinates;
  final List<double> marsCoordinates;
  final List<double> jupiterCoordinates;
  final List<double> saturnCoordinates;
  final List<double> uranusCoordinates;
  final List<double> neptuneCoordinates;
  final List<double> plutoCoordinates;
  final List<double> ceresCoordinates;
  final List<double> halleysCoordinates;
  final List<double> lovejoy11Coordinates;

  final List<double> moonCoordinates;

  final List<List<List<double>>> planetPositions;

  SolarSystem({
    required this.earthCoordinates,
    required this.mercuryCoordinates,
    required this.venusCoordinates,
    required this.marsCoordinates,
    required this.jupiterCoordinates,
    required this.saturnCoordinates,
    required this.uranusCoordinates,
    required this.neptuneCoordinates,
    required this.moonCoordinates,
    required this.planetPositions,
    required this.plutoCoordinates,
    required this.ceresCoordinates,
    required this.halleysCoordinates,
    required this.lovejoy11Coordinates,
  });

  @override
  _SolarSystemState createState() => _SolarSystemState();
}

class PlanetOrbitsPainter extends CustomPainter {
  final double sunPosX;
  final double sunPosY;
  final List<List<List<double>>> planetPositions;

  PlanetOrbitsPainter(this.sunPosX, this.sunPosY, this.planetPositions);

  @override
  void paint(Canvas canvas, Size size) {
    // Translate the canvas to position the Sun at the center
    canvas.translate(sunPosX, sunPosY);

    // Orbits data: [semi-major axis (AU), eccentricity]
    Paint orbitPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;
    // Draw orbits for each planet
    for (int i = 0; i < 12; i++) {
      if (i == 8) {
        Paint orbitPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = .05;

        Path orbitPath = Path();
        orbitPath.moveTo(
            planetPositions[i][0][0] * 30, -planetPositions[i][0][1] * 30);
        for (var j = 1; j < planetPositions[i].length; j++) {
          orbitPath.lineTo(
              planetPositions[i][j][0] * 30, -planetPositions[i][j][1] * 30);
        }
        canvas.drawPath(orbitPath, orbitPaint);
      } else {
        Path orbitPath = Path();
        orbitPath.moveTo(
            planetPositions[i][0][0] * 30, -planetPositions[i][0][1] * 30);
        for (var j = 1; j < planetPositions[i].length; j++) {
          orbitPath.lineTo(
              planetPositions[i][j][0] * 30, -planetPositions[i][j][1] * 30);
        }
        canvas.drawPath(orbitPath, orbitPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}



class _SolarSystemState extends State<SolarSystem> {
  double scale = 1.0; // Initial scale value, can be adjusted

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateLocations());
    // Start the timer to update JD every second
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _updateLocations();
    });
  }

  double screenWidth = 0;
  double screenHeight = 0;
  double screenx = 0;
  double screeny = 0;
  double sunX = 0;
  double sunY = 0;
  double centerX = 0;
  double centerY = 0;
  double sunPosX = 0;
  double sunPosY = 0;
  double astroScale = 30.0;
  double mercuryLeft = 0;
  double mercuryTop = 0;
  double venusLeft = 0;
  double venusTop = 0;
  double earthLeft = 0;
  double earthTop = 0;
  double marsLeft = 0;
  double marsTop = 0;
  double jupiterLeft = 0;
  double jupiterTop = 0;
  double saturnLeft = 0;
  double saturnTop = 0;
  double uranusLeft = 0;
  double uranusTop = 0;
  double neptuneLeft = 0;
  double neptuneTop = 0;
  double plutoLeft = 0;
  double plutoTop = 0;
  double ceresLeft = 0;
  double ceresTop = 0;
  double halleysLeft = 0;
  double halleysTop = 0;
  double lovejoy11sleft = 0;
  double lovejoy11stop = 0;

  double moonLeft = 0;
  double moonTop = 0;

  double earthPx = 0;
  double earthPy = 0;

  TransformationController _transformationController =
      TransformationController();

  _updateLocations() {
    getPerms();

    DateTime time = DateTime.now().toUtc();

    double _currentJD = JulianDate.gregorianDateToJulianDate(
        time.year, time.month, time.day, time.hour, time.minute, time.second);

    double angle = earthOrientation(currentPos.latitude, _currentJD);

    mercuryLeft = sunPosX + (widget.mercuryCoordinates[0] * astroScale);
    mercuryTop = sunPosY + (-widget.mercuryCoordinates[1] * astroScale);

    venusLeft = sunPosX + (widget.venusCoordinates[0] * astroScale);
    venusTop = sunPosY + (-widget.venusCoordinates[1] * astroScale);

    earthLeft = sunPosX + (widget.earthCoordinates[0] * astroScale);
    earthTop = sunPosY + (-widget.earthCoordinates[1] * astroScale);



    double angleBetweenSunAndEarth =
        atan2(sunPosY - earthTop, sunPosX - earthLeft);

    earthPx = 2 * cos(degreesToRadians(angle) + angleBetweenSunAndEarth);
    earthPy = 2 * sin(degreesToRadians(angle) + angleBetweenSunAndEarth);

    marsLeft = sunPosX + (widget.marsCoordinates[0] * astroScale);
    marsTop = sunPosY + (-widget.marsCoordinates[1] * astroScale);

    jupiterLeft = sunPosX + (widget.jupiterCoordinates[0] * astroScale);
    jupiterTop = sunPosY + (-widget.jupiterCoordinates[1] * astroScale);

    saturnLeft = sunPosX + (widget.saturnCoordinates[0] * astroScale);
    saturnTop = sunPosY + (-widget.saturnCoordinates[1] * astroScale);

    uranusLeft = sunPosX + (widget.uranusCoordinates[0] * astroScale);
    uranusTop = sunPosY + (-widget.uranusCoordinates[1] * astroScale);

    neptuneLeft = sunPosX + (widget.neptuneCoordinates[0] * astroScale);
    neptuneTop = sunPosY + (-widget.neptuneCoordinates[1] * astroScale);



    moonLeft = earthLeft + (widget.moonCoordinates[0] * astroScale * 50);
    moonTop = earthTop - (widget.moonCoordinates[1] * astroScale * 50);

    plutoLeft = sunPosX + (widget.plutoCoordinates[0] * astroScale);
    plutoTop = sunPosY + (-widget.plutoCoordinates[1] * astroScale);

    ceresLeft = sunPosX + (widget.ceresCoordinates[0] * astroScale);
    ceresTop = sunPosY + (-widget.ceresCoordinates[1] * astroScale);

    halleysLeft = sunPosX + (widget.halleysCoordinates[0] * astroScale);
    halleysTop = sunPosY + (-widget.halleysCoordinates[1] * astroScale);

    lovejoy11sleft = sunPosX + (widget.lovejoy11Coordinates[0] * astroScale);
    lovejoy11stop = sunPosY + (-widget.lovejoy11Coordinates[1] * astroScale);


    handleTap(sunPosX, sunPosY);

    _transformationController.value = Matrix4.diagonal3Values(0.5, 0.5, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    screenx = screenWidth;
    screeny = screenHeight;

    // Calculate the center of the screen
    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    // Update the sun position based on scale
    sunPosX = centerX * 2;
    sunPosY = centerY * 2;

    sunX = sunPosX;
    sunY = sunPosY;

    return Scaffold(
        body: GestureDetector(
      onTap: () {
        // Clear the selected planet and displayed text
        setState(() {
          selectedPlanet = -1;
        });
      },
      child: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.05,
            maxScale: 12.5,
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: SizedBox(
              width: screenWidth * 4,
              height: screenHeight * 4,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: PlanetOrbitsPainter(
                        sunPosX, sunPosY, widget.planetPositions),
                    size: Size(screenWidth * 4, screenHeight * 4),
                  ),

                  // Sun
                  Positioned(
                    left: sunPosX - (6.75),
                    top: sunPosY - (6.75),
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 0;
                          planet = "Sun";
                        });

                        handleTap(sunPosX, sunPosY);
                      },
                      child: Container(
                        width: 13.5,
                        height: 13.5,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow,
                        ),
                      ),
                    ),
                  ),

                  // Mercury
                  Positioned(
                    left: mercuryLeft - 1,
                    top: mercuryTop - 1,

                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 1;
                          planet = "Mercury";
                        });

                        handleTap(mercuryLeft, mercuryTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 2.0,
                        height: 2.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),

                  // Venus
                  Positioned(
                    left: venusLeft - 2.48,
                    top: venusTop - 2.48,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 2;
                          planet = "Venus";
                        });

                        handleTap(venusLeft, venusTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 4.96,
                        height: 4.96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 155, 83, 35),
                        ),
                      ),
                    ),
                  ),

                  // Earth
                  Positioned(
                    left: earthLeft - 2.61,
                    top: earthTop - 2.61,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 3;
                          planet = "Earth";
                        });

                        handleTap(earthLeft, earthTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 5.22,
                        height: 5.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: Stack(
                          children: [
                            // Red dot at the edge of the circle
                            Positioned(
                              left: 2.61 +
                                  earthPx, // Adjust the position as needed
                              top: 2.61 +
                                  earthPy, // Adjust the position as needed
                              child: Container(
                                width: 1, // Adjust the size of the red dot
                                height: 1, // Adjust the size of the red dot
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

// Moon
                  Positioned(
                    left: moonLeft - 1,
                    top: moonTop - 1,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 9;
                          planet = "Moon";
                        });

                        handleTap(moonLeft, moonTop);
                      },
                      child: Container(
                        width: 2.6,
                        height: 2.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors
                                .white24, // Set the color of the circular outline
                            width: .15, // Set the width of the circular outline
                          ),
                        ),
                        child: Image.asset(
                          moonPhaseAddress,
                          width: 2.5,
                          height: 2.5,
                        ),
                      ),
                    ),
                  ),

                  // Mars
                  Positioned(
                    left: marsLeft - 1.39,
                    top: marsTop - 1.39,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 4;
                          planet = "Mars";
                        });

                        handleTap(marsLeft, marsTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 2.78,
                        height: 2.78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 51, 36, 4),
                        ),
                      ),
                    ),
                  ),

                  // Jupiter
                  Positioned(
                    left: jupiterLeft - 28.64,
                    top: jupiterTop - 28.64,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 5;
                          planet = "Jupiter";
                        });

                        handleTap(jupiterLeft, jupiterTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 57.28,
                        height: 57.28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 212, 103, 84),
                        ),
                      ),
                    ),
                  ),

                  // Saturn
                  Positioned(
                    left: saturnLeft - 23.87,
                    top: saturnTop - 23.87,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 6;
                          planet = "Saturn";
                        });

                        handleTap(saturnLeft, saturnTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 47.74,
                        height: 47.74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 192, 61, 37),
                        ),
                      ),
                    ),
                  ),

                  // Uranus
                  Positioned(
                    left: uranusLeft - 10.39,
                    top: uranusTop - 10.39,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 7;
                          planet = "Uranus";
                        });

                        handleTap(uranusLeft, uranusTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 20.78,
                        height: 20.78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 55, 131, 141),
                        ),
                      ),
                    ),
                  ),

                  // Neptune
                  Positioned(
                    left: neptuneLeft - 10.08,
                    top: neptuneTop - 10.08,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 8;
                          planet = "Neptune";
                        });

                        handleTap(neptuneLeft, neptuneTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 20.16,
                        height: 20.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 97, 33, 150),
                        ),
                      ),
                    ),
                  ),

                  // Pluto
                  Positioned(
                    left: plutoLeft - 6.08,
                    top: plutoTop - 6.08,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 10;
                          planet = "Pluto";
                        });

                        handleTap(plutoLeft, plutoTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 12.16,
                        height: 12.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 194, 30, 44),
                        ),
                      ),
                    ),
                  ),

                  // Ceres
                  Positioned(
                    left: ceresLeft - 6.08,
                    top: ceresTop - 6.08,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 11;
                          planet = "Ceres";
                        });

                        handleTap(ceresLeft, ceresTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 12.16,
                        height: 12.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 45, 154, 85),
                        ),
                      ),
                    ),
                  ),
                  // Halleys
                  Positioned(
                    left: halleysLeft - 3.08,
                    top: halleysTop - 3.08,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 12;
                          planet = "Halley's Comet";
                        });

                        handleTap(halleysLeft, halleysTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 6.16,
                        height: 6.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 154, 215, 219),
                        ),
                      ),
                    ),
                  ),
                  // Lovejoy 11
                  Positioned(
                    left: lovejoy11sleft - 3.08,
                    top: lovejoy11stop - 3.08,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 13;
                          planet = "Lovejoy 11";
                        });

                        handleTap(halleysLeft, halleysTop);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 6.16,
                        height: 6.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 154, 86, 194),
                        ),
                      ),
                    ),
                  ),
                  // Add the custom painter for orbits
                  // Display specified text for the selected planet
                ],
              ),
            ),
          ),
          )
        ],
      ),
    ));
  }

  // Function to handle the tap gesture and focus on the selected planet
  void handleTap(double planetLeft, double planetTop) {
    // Calculate the center of the screen
    centerX = screenx / 2;
    centerY = screeny / 2;

    // Calculate the position to focus on (selected planet's position)
    double offsetX = screenx / 2 -
        (planetLeft * _transformationController.value.getMaxScaleOnAxis());
    double offsetY = screeny / 2 -
        (planetTop * _transformationController.value.getMaxScaleOnAxis());

    // Update the TransformationController to focus on the selected planet
    _transformationController.value = Matrix4.identity()
      ..translate(
          -((planetLeft * _transformationController.value.getMaxScaleOnAxis()) -
              screenx / 2),
          -((planetTop * _transformationController.value.getMaxScaleOnAxis()) -
                  screeny / 2) -
              50)
      ..scale(_transformationController.value
          .getMaxScaleOnAxis()); // Adjust the scale as needed
  }
}
