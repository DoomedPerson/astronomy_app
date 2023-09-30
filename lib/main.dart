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
List<String> planetNames = [
  "Sun",
  "Mercury",
  "Venus",
  "Earth",
  "Mars",
  "Jupiter",
  "Saturn",
  "Uranus",
  "Neptune"
];

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

List<List<List<double>>> calculatePlanetPositions() {
  final yearLengths = {
    88 / 60,
    225 / 60,
    365 / 60,
    687 / 60,
    4333 / 60,
    10756 / 60,
    30687 / 60,
    60190 / 60
  };
  List<List<List<double>>> positions = [];

  DateTime time = DateTime.now().toUtc();
  double currentJD = JulianDate.gregorianDateToJulianDate(
      time.year, time.month, time.day, time.hour, time.minute, time.second);

  double t = jd2et(currentJD);

  for (int i = 0; i < 8; i++) {
    int length = yearLengths.elementAt(i).toInt();
    List<List<double>> planetPositionsForYear = [];

    for (int j = 0; j < 61; j++) {
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

  selectedPlanetInfo[0] = info.elementAt(3); // azimuth
  selectedPlanetInfo[1] = info.elementAt(4); // altitude
  selectedPlanetInfo[2] = sunDistance; // sun dist
  selectedPlanetInfo[3] = earthDistance; // earth dist
  selectedPlanetInfo[4] = lightSeconds; // light seconds
  selectedPlanetInfo[5] = (info.elementAt(0) - 7) % 24; // trans
  selectedPlanetInfo[6] = (info.elementAt(1) - 7) % 24; // rise
  selectedPlanetInfo[7] = (info.elementAt(2) - 7) % 24; // set
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

  // longitude, latitude, radius, right-ascension, declination
  List<List<double>> coordinates = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0]
  ];

  bool _hasPermissions = false;

  List<double> info = [0, 0, 0];

  double distanceFromSun = 0.0;
  double distanceFromEarth = 0.0;
  String lightDistance = '';
  String planet = '';

  double transit = 0;
  double set = 0;
  double rise = 0;

  double _heading = 0.0;
  double _pitch = 0.0;

  bool guidingMode = false; // Variable to track guiding mode

  double azimuthDifference = 0.0;
  double altitudeDifference = 0.0;

  // Update device orientation based on sensor data
  Future<void> _initCompass() async {
    FlutterCompass.events?.listen((event) {
      if (event?.heading != null) {
        setState(() {
          _heading = (event.heading! + 360) % 360;
        });
      }
    });
  }

  Widget buildArrow(double azimuthDifference) {
    azimuthDifference = _heading - selectedPlanetInfo[0];
    // Rotate the arrow based on azimuth difference
    return Transform.rotate(
      angle: ((-(azimuthDifference + 90)) * (pi / 180)),
      child: Icon(
        Icons.arrow_forward,
        size: 50.0,
        color: Colors.red, // Adjust color as needed
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
        print("hey");
        print(_currentJD);
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
    marsTemp = Vsop87aMicro.getMars(t);

    jupiterTemp = Vsop87aMicro.getJupiter(t);
    saturnTemp = Vsop87aMicro.getSaturn(t);
    uranusTemp = Vsop87aMicro.getUranus(t);
    neptuneTemp = Vsop87aMicro.getNeptune(t);

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
              planetPositions: widget.planetPositions,
            ),

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
                  Text(
                    '$planet',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 105, 105, 105),
                    ),
                  ),
                  Text(
                    'Distance From Sun: $distanceFromSun',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 105, 105, 105),
                    ),
                  ),
                  Text(
                    'Distance From Earth: $distanceFromEarth\nLight Hours From Earth: $lightDistance',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 105, 105, 105),
                    ),
                  ),
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
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      guidingMode = !guidingMode;
                    });
                  },
                  child: Text(guidingMode
                      ? 'Deactivate Guiding Mode'
                      : 'Activate Guiding Mode'),
                ),
              ),
            ),
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
    required this.planetPositions,
  });

  @override
  _SolarSystemState createState() => _SolarSystemState();
}

class PlanetOrbitsPainter extends CustomPainter {
  final double sunPosX;
  final double sunPosY;
  final List<List<List<double>>> planetPositions; // Added parameter

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
    for (int i = 0; i < 8; i++) {
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
    _timer = Timer.periodic(Duration(seconds: 120), (timer) {
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

  _updateLocations() {
    mercuryLeft = sunPosX + (widget.mercuryCoordinates[0] * astroScale);
    mercuryTop = sunPosY + (-widget.mercuryCoordinates[1] * astroScale);

    venusLeft = sunPosX + (widget.venusCoordinates[0] * astroScale);
    venusTop = sunPosY + (-widget.venusCoordinates[1] * astroScale);

    earthLeft = sunPosX + (widget.earthCoordinates[0] * astroScale);
    earthTop = sunPosY + (-widget.earthCoordinates[1] * astroScale);

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
  }

  TransformationController _transformationController =
      TransformationController();

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
          InteractiveViewer(
            boundaryMargin: EdgeInsets.only(
                left: 1250.0, top: 1750.0, right: 500.0, bottom: 250.0),
            minScale: 0.1,
            maxScale: 7.5,
            transformationController: _transformationController,
            constrained: false,
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
                      ),
                    ),
                  ),

                  // Moon
                  /*Positioned(
                    left: 220.0,
                    top: 150.0,
                    child: Container(
                      alignment: Alignment.center,
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                    ),
                  ),*/

                  // Mars
                  Positioned(
                    left: marsLeft - 1.39,
                    top: marsTop - 1.39,
                    child: GestureDetector(
                      onTap: () {
                        // Set the selected planet and associated text
                        setState(() {
                          selectedPlanet = 4;
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
                  // Add the custom painter for orbits
                  // Display specified text for the selected planet
                ],
              ),
            ),
          ),
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
