import 'dart:math';
import 'dart:ui';
import 'package:astronomy_app/main.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'jo7implementation.dart';
import 'TESTff.dart';

double JD = 0;

class JulianDate {
  static int INT(double d) {
    if (d > 0) {
      return d.floor();
    }
    if (d == d.floorToDouble()) return d.toInt();
    return (d.floor() - 1).toInt();
  }

  static double gregorianDateToJulianDate(
      int year, int month, int day, int hour, int min, int sec) {
    bool isGregorian = true;
    if (year < 1582 ||
        (year == 1582 && (month < 10 || (month == 10 && day < 5)))) {
      isGregorian = false;
    }

    if (month < 3) {
      year = year - 1;
      month = month + 12;
    }

    int b = 0;
    if (isGregorian) {
      int a = INT(year / 100.0);
      b = 2 - a + INT(a / 4.0);
    }

    double jd = INT(365.25 * (year + 4716)) +
        INT(30.6001 * (month + 1)) +
        day +
        b -
        1524.5;
    jd += hour / 24.0;
    jd += min / 24.0 / 60.0;
    jd += sec / 24.0 / 60.0 / 60.0;
    return jd;
  }
}

double degreesToRadians(double degrees) {
  return degrees * (pi / 180.0);
}

double jd2et(double jd) {
  return (jd - 2451545.0) / 365250.0;
}

(int, int, double) jDToGregorian(double jD) {
  jD = jD + 0.5;

  int Z = (jD).floor();
  double F = jD - Z;

  int A = Z;

  if (Z >= 2299161) {
    int alpha = ((Z - 1867216.25) / 36524.25).floor();

    A = Z + 1 + alpha - (alpha / 4).floor();
  }

  int B = A + 1524;

  int C = ((B - 122.1) / 365.25).floor();

  int D = (365.25 * C).floor();

  int E = ((B - D) / 30.6001).floor();

  double day = B - D - (30.6001 * E).floor() + F;

  int month = (E < 14 ? E - 1 : E - 13);

  int year = (month > 2 ? C - 4716 : C - 4715);

  return (year, month, day);
}

double deltaT(int year) {
  double t = (year - 2000) / 100;

  double deltaT = 0;

  if ((year > 948 && year < 1600) || (year > 2000)) {
    deltaT = 102 + (102 * t) + (25.3 * (t * t));

    if (year > 2000 && year < 2100) deltaT += 0.37 * (year - 2100);
  }

  return deltaT; // UT = TD - Delta T; TD = UT + Delta T;
}

double calculateDistance(
    double x1, double y1, double z1, double x2, double y2, double z2) {
  double distance = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2) + pow(z2 - z1, 2));
  return distance;
}

List<double> eclipticToCartesianCoordinates(
    double distance, double longitude, double latitude) {
  double x = distance * cos(latitude) * cos(longitude);
  double y = distance * cos(latitude) * sin(longitude);
  double z = distance * sin(latitude);

  return [x, y, z];
}

String formatTimeWithLeadingZeros(int value) {
  return value < 10 ? '0$value' : value.toString();
}

String convertSecondsToHoursMinutesSeconds(int seconds) {
  int hours = (seconds ~/ 3600).floor();
  int minutes = ((seconds % 3600) ~/ 60).floor();
  int remainingSeconds = (seconds % 60);

  String formattedHours = formatTimeWithLeadingZeros(hours);
  String formattedMinutes = formatTimeWithLeadingZeros(minutes);
  String formattedSeconds = formatTimeWithLeadingZeros(remainingSeconds);

  return '$formattedHours:$formattedMinutes:$formattedSeconds';
}

double GMST(double jd) {
  double T = (jd - 2451545.0) / 36525.0;
  double st = 280.46061837 +
      360.98564736629 * (jd - 2451545.0) +
      0.000387933 * T * T -
      T * T * T / 38710000.0;
  st = st % 360;
  if (st < 0) {
    st += 360;
  }

  return st;
  //return st*Math.PI/180.0;
}

double radToDeg(double rad) {
  return rad * (180.0 / 3.141592653589793238463);
}

List<double> helioToGeo(List<double> target, List<double> earth) {
  return [target[0] - earth[0], target[1] - earth[1], target[2] - earth[2]];
}

List<double> cartesianToEclipticCoordinates(List<double> target) {
  double x = target[0];
  double y = target[1];
  double z = target[2];
  // Convert from Cartesian to polar coordinates
  double r = sqrt(x * x + y * y + z * z);
  double l = atan2(y, x);
  double t = acos(z / r);

  // Make sure RA is positive, and Dec is in range +/-90
  if (l < 0) {
    l += 2 * pi;
  }
  t = 0.5 * pi - t;

  double obliquity = 23.4397 * (pi / 180.0); // Earth's obliquity in radians

  double Z_equatorial = y * sin(obliquity) + z * cos(obliquity);

  // Update declination (DEC) using the new Z_equatorial coordinate
  t = asin(Z_equatorial / r);

  return [l, t, r];
}

List<double> geocartesianToEclipticCoordinates(double x, double y, double z) {
  // Convert from Cartesian to polar coordinates
  double r = sqrt(x * x + y * y + z * z);
  double l = atan2(y, x);
  double t = acos(z / r);

  // Make sure RA is positive, and Dec is in range +/-90
  if (l < 0) {
    l += 2 * pi;
  }
  t = 0.5 * pi - t;

  return [l, t, r];
}

double constrain(double v) {
  if (v < 0) {
    return v + 1;
  }
  if (v > 1) {
    return v - 1;
  }
  return v;
}

List<List<double>> getRaDec(planet, year) {
  double asc1 = 1;
  double asc2 = 1;
  double asc3 = 1;

  double dec1 = 1;
  double dec2 = 1;
  double dec3 = 1;
  if (planet < 0) {
    return [
      [0, 0, 0],
      [0, 0, 0]
    ];
  }

  if (planet >= 0) {
    List<double> Temp1 = [0, 0, 0];
    List<double> Temp2 = [0, 0, 0];
    List<double> Temp3 = [0, 0, 0];
    switch (planet) {
      case 0:
        break;
      case 1:
        Temp1 = Vsop87aMicro.getMercury(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getMercury(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getMercury(jd2et((year.floor() + .5) + 1));
        break;
      case 2:
        Temp1 = Vsop87aMicro.getVenus(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getVenus(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getVenus(jd2et((year.floor() + .5) + 1));
        break;
      case 3:
        Temp1 = Vsop87aMicro.getEarth(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getEarth(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getEarth(jd2et((year.floor() + .5) + 1));
        break;
      case 4:
        Temp1 = Vsop87aMicro.getMars(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getMars(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getMars(jd2et((year.floor() + .5) + 1));
        break;
      case 5:
        Temp1 = Vsop87aMicro.getJupiter(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getJupiter(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getJupiter(jd2et((year.floor() + .5) + 1));
        break;
      case 6:
        Temp1 = Vsop87aMicro.getSaturn(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getSaturn(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getSaturn(jd2et((year.floor() + .5) + 1));
        break;
      case 7:
        Temp1 = Vsop87aMicro.getUranus(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getUranus(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getUranus(jd2et((year.floor() + .5) + 1));
        break;
      case 8:
        Temp1 = Vsop87aMicro.getNeptune(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getNeptune(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getNeptune(jd2et((year.floor() + .5) + 1));
        break;
      case 9:
        Temp1 = Vsop87aMicro.getEmb(jd2et((year.floor() + .5) - 1));
        Temp2 = Vsop87aMicro.getEmb(jd2et((year.floor() + .5)));
        Temp3 = Vsop87aMicro.getEmb(jd2et((year.floor() + .5) + 1));
        break;
    }

    List<double> ecoord1 = cartesianToEclipticCoordinates(helioToGeo(
        Temp1, Vsop87aMicro.getEarth(jd2et((year.floor() + .5) - 1))));
    List<double> ecoord2 = cartesianToEclipticCoordinates(
        helioToGeo(Temp2, Vsop87aMicro.getEarth(jd2et((year.floor() + .5)))));
    List<double> ecoord3 = cartesianToEclipticCoordinates(helioToGeo(
        Temp3, Vsop87aMicro.getEarth(jd2et((year.floor() + .5) + 1))));

    asc1 = ecoord1[0];
    asc2 = ecoord2[0];
    asc3 = ecoord3[0];

    //print(Temp2);
    //print(Vsop87aMicro.getEarth(jd2et((year.floor() + .5))));

    dec1 = ecoord1[1];
    dec2 = ecoord2[1];
    dec3 = ecoord3[1];
  }

  return [
    [asc1, asc2, asc3],
    [dec1, dec2, dec3]
  ];
}

List<double> raDecToAltAz(
    double ra, double dec, double lat, double lon, double jd_ut) {
  // Meeus 13.5 and 13.6, modified so West longitudes are negative and 0 is North
  double gmst = greenwichMeanSiderealTime(jd_ut);
  double localSiderealTime = (gmst + lon) % (2 * pi);

  double H = (localSiderealTime - ra);
  if (H < 0) {
    H += (2 * pi);
  }
  if (H > pi) {
    H -= (2 * pi);
  }

  double az = (atan2(sin(H), cos(H) * sin(lat) - tan(dec) * cos(lat)));
  double a = (asin(sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(H)));
  az -= pi;

  if (az < 0) {
    az += 2 * pi;
  }
  return [az, a, localSiderealTime, H];
}

double greenwichMeanSiderealTime(double jd) {
  // "Expressions for IAU 2000 precession quantities" N. Capitaine1, P.T.Wallace2, and J. Chapront
  double t = ((jd - 2451545.0)) / 36525.0;

  double gmst = earthRotationAngle(jd) +
      (0.014506 +
              4612.156534 * t +
              1.3915817 * t * t -
              0.00000044 * t * t * t -
              0.000029956 * t * t * t * t -
              0.0000000368 * t * t * t * t * t) /
          60.0 /
          60.0 *
          pi /
          180.0; // eq 42
  gmst %= 2 * pi;
  if (gmst < 0) gmst += 2 * pi;

  return gmst;
}

double earthRotationAngle(double jd) {
  // IERS Technical Note No. 32
  double t = jd - 2451545.0;
  double f = jd % 1.0;

  double theta =
      2 * pi * (f + 0.7790572732640 + 0.00273781191135448 * t); // eq 14
  theta %= 2 * pi;
  if (theta < 0) theta += 2 * pi;

  return theta;
}

const toDeg = 180.0 / pi;

List<double> getBodyLightAdjusted(List<double> origin, int body, double jd) {
  double jdLight = jd;
  List<double> b = [0, 0, 0];
  const c = 299792458; // m/s
  const au = 149597870691; // meters

  for (var i = 0; i < 2; i++) {
    b = Vsop87aMicro.getBody(body, jd2et(jdLight));
    final r = sqrt((origin[0] - b[0]) * (origin[0] - b[0]) +
        (origin[1] - b[1]) * (origin[1] - b[1]) +
        (origin[2] - b[2]) * (origin[2] - b[2]));
    final lightTime = r / (c / au * 60 * 60 * 24);
    jdLight = jd - lightTime;
  }

  return b;
}

const torad = pi/180.0;

double sind(r){
  return sin(r*torad);
}

double cosd(r){
  return cos(r*torad);
}

List<double> getGeocentricMoonPos(jd){
  double T = (jd-2451545)/36525;
  double L = 218.32 + 481267.881*T + 6.29*sind(135.0 + 477198.87*T) - 1.27*sind(259.3 - 413335.36*T) + 0.66*sind(235.7 + 890534.22*T) + 0.21*sind(269.9 + 954397.74*T) - 0.19*sind(357.5 + 35999.05*T) - 0.11*sind(186.5 + 966404.03*T);
  double B = 5.13*sind( 93.3 + 483202.02*T) + 0.28*sind(228.2 + 960400.89*T) - 0.28*sind(318.3 + 6003.15*T) - 0.17*sind(217.6 - 407332.21*T);
  double P = 0.9508 + 0.0518*cosd(135.0 + 477198.87*T) + 0.0095*cosd(259.3 - 413335.36*T) + 0.0078*cosd(235.7 + 890534.22*T) + 0.0028*cosd(269.9 + 954397.74*T);

  double SD=0.2724*P;
  double r=1/sind(P);

  double l = cosd(B) * cosd(L);
  double m = 0.9175*cosd(B)*sind(L) - 0.3978*sind(B);
  double n = 0.3978*cosd(B)*sind(L) + 0.9175*sind(B);

  double ra = atan2(m,l);
  if(ra<0){ra+=2*pi;}
  double dec = asin(n);

  print(radToDeg(ra));
  print(radToDeg(dec));
  return [ra,dec];
}

double lunaryear = 29.53058770576;
double lunarsecs = lunaryear * (24 * 60 *60);

String moonPhase(double epnewmoon, double jd)
{
  double currSecs = (jd-epnewmoon) % lunaryear;

  if (currSecs < 0)
    {
      currSecs += epnewmoon;
    }

  double currAge = currSecs;

  print(currAge);

  if (currAge > 28.53 || currAge < 1)
    {
      return "assets/images/newMoon.png";
    }
  else if (currAge > 1 && currAge < 6.38264692644)
    {
      return "assets/images/waxingCrescent.png";
    }
  else if (currAge >= 1 && currAge < 6.38264692644)
  {
    return "assets/images/waxingCrescent.png";
  }
  else if (currAge >= 6.38264692644 && currAge < 8.3826492644)
  {
    return "assets/images/firstQuarter.png";
  }
  else if (currAge >= 8.3826492644 && currAge < 13.76529385288)
  {
    return "assets/images/waxingGibbous.png";
  }
  else if (currAge >= 13.76529385288 && currAge < 15.76529385288)
  {
    return "assets/images/fullMoon.png";
  }
  else if (currAge >= 15.76529385288 && currAge < 21.14794077932)
  {
    return "assets/images/waningGibbous.png";
  }
  else if (currAge >= 21.14794077932 && currAge < 23.14794077932)
  {
    return "assets/images/secondQuarter.png";
  }
  else if (currAge >= 23.14794077932 && currAge < 28.53058770576)
  {
    return "assets/images/waningCrescent.png";
  }

  return "assets/images/fullMoon.png";
}

double subSolarPointLon = 147.68;
double subSolarLongJD = 2460242.578761574;

double earthOrientation(double long, double jd)
{

  double timePast = jd-subSolarLongJD;

  double hoursPast = timePast % 0.977947983;

  double angle = 360*hoursPast;

  double pointSpot = angle+(long-subSolarPointLon);

  return pointSpot;
}

List<double> riseSetInfo(int planet, double year, Position pos) {
  if (planet == 3) {
    return [0, 0, 0];
  }

  double L = degreesToRadians(-pos.longitude);
  double lat = degreesToRadians(pos.latitude);

  //final h0 = -0.8333; // For Sun
  double h0 = -0.5667; // For stars and planets

  if (planet == 0) h0 = -0.8333;
  if (planet == 9)
    {
      double h0 = 0.125;

      List<double> radec = getGeocentricMoonPos(year);

      List<List<double>> ascdec = [getGeocentricMoonPos((year.floor() + .5) - 1),getGeocentricMoonPos((year.floor() + .5)),getGeocentricMoonPos((year.floor() + .5) + 1)];

      List<double> altaz = raDecToAltAz(radec[0], radec[1], lat, -L, year);

      print(altaz[0]);
      print(altaz[1]);

      double cosH = (sin(h0 * pi / 180.0) - sin(lat) * sin(ascdec[1][1])) /
          (cos(lat) * cos(ascdec[1][1]));
      double H0 = acos(cosH) * 180.0 / pi;

      double gmst = GMST(year.floor() + .5);

      double transit = ((ascdec[0][1] * toDeg) + (L * toDeg) - gmst) / 360.0;
      double rise = transit - (H0 / 360.0);
      double set = transit + (H0 / 360.0);

      double m0 = transit;
      double m1 = rise;
      double m2 = set;

      double thetaTransit = gmst + (360.985647 * m0);
      double thetaRise = gmst + (360.985647 * m1);
      double thetaSet = gmst + (360.985647 * m2);

      int yearG = 0;
      int month = 0;
      double day = 0.0;

      (yearG, month, day) = jDToGregorian(year.toDouble());

      double dT = deltaT(yearG);

      double n0 = m0 + dT / 86400;
      double n1 = m1 + dT / 86400;
      double n2 = m2 + dT / 86400;

      double a = ascdec[0][0] - ascdec[0][0];
      double b = ascdec[1][0] - ascdec[1][0];
      double c = ascdec[2][0] + ascdec[2][0] - (2 * ascdec[1][0]);

      double transitAsc = ascdec[1][0] + ((n0 / 2) * a + b + (n0 * c));
      double riseAsc = ascdec[1][0] + ((n1 / 2) * a + b + (n1 * c));
      double setAsc = ascdec[1][0] + ((n2 / 2) * a + b + (n2 * c));

      a = ascdec[0][1] - ascdec[0][1];
      b = ascdec[1][1] - ascdec[1][1];
      c = ascdec[2][1] + ascdec[2][1] - (2 * ascdec[1][1]);

      double riseDec = ascdec[1][1] + (n1 / 2) * (a + b + (n1 * c));
      double setDec = ascdec[1][1] + (n2 / 2) * (a + b + (n2 * c));

      double transH = thetaTransit - (L * toDeg) - radToDeg(transitAsc);
      double riseH = thetaRise - (L * toDeg) - radToDeg(riseAsc);
      double setH = thetaSet - (L * toDeg) - radToDeg(setAsc);

      double riseh = asin(sin(lat) * sin(riseDec) +
          cos(lat) * cos(riseDec) * cos(degreesToRadians(riseH)));
      double seth = asin(sin(lat) * sin(setDec) +
          cos(lat) * cos(setDec) * cos(degreesToRadians(setH)));

      double deltaMtransit = -(transH / 360);

      double deltaMrise = (radToDeg(riseh) - h0) /
          (360 * cos(riseDec) * cos(lat) * sin(degreesToRadians(riseH)));
      double deltaMset = (radToDeg(seth) - h0) /
          (360 * cos(setDec) * cos(lat) * sin(degreesToRadians(setH)));

      transH += deltaMtransit;
      rise += deltaMrise;
      set += deltaMset;

      return [
        constrain(transit) * 24.0,
        constrain(rise) * 24.0,
        constrain(set) * 24.0,
        radToDeg(altaz[0]),
        radToDeg(altaz[1]),
      ];

    }

  List<List<double>> ascdec = getRaDec(planet, year);

  double cosH = (sin(h0 * pi / 180.0) - sin(lat) * sin(ascdec[1][1])) /
      (cos(lat) * cos(ascdec[1][1]));
  double H0 = acos(cosH) * 180.0 / pi;

  double gmst = GMST(year.floor() + .5);

  double transit = ((ascdec[0][1] * toDeg) + (L * toDeg) - gmst) / 360.0;
  double rise = transit - (H0 / 360.0);
  double set = transit + (H0 / 360.0);

  double m0 = transit;
  double m1 = rise;
  double m2 = set;

  double thetaTransit = gmst + (360.985647 * m0);
  double thetaRise = gmst + (360.985647 * m1);
  double thetaSet = gmst + (360.985647 * m2);

  int yearG = 0;
  int month = 0;
  double day = 0.0;

  (yearG, month, day) = jDToGregorian(year.toDouble());

  double dT = deltaT(yearG);

  double n0 = m0 + dT / 86400;
  double n1 = m1 + dT / 86400;
  double n2 = m2 + dT / 86400;

  double a = ascdec[0][1] - ascdec[0][0];
  double b = ascdec[0][2] - ascdec[0][1];
  double c = ascdec[0][0] + ascdec[0][2] - (2 * ascdec[0][1]);

  double transitAsc = ascdec[0][1] + ((n0 / 2) * a + b + (n0 * c));
  double riseAsc = ascdec[0][1] + ((n1 / 2) * a + b + (n1 * c));
  double setAsc = ascdec[0][1] + ((n2 / 2) * a + b + (n2 * c));

  a = ascdec[1][1] - ascdec[1][0];
  b = ascdec[1][2] - ascdec[1][1];
  c = ascdec[1][0] + ascdec[1][2] - (2 * ascdec[1][1]);

  double riseDec = ascdec[1][1] + (n1 / 2) * (a + b + (n1 * c));
  double setDec = ascdec[1][1] + (n2 / 2) * (a + b + (n2 * c));

  double transH = thetaTransit - (L * toDeg) - radToDeg(transitAsc);
  double riseH = thetaRise - (L * toDeg) - radToDeg(riseAsc);
  double setH = thetaSet - (L * toDeg) - radToDeg(setAsc);

  double riseh = asin(sin(lat) * sin(riseDec) +
      cos(lat) * cos(riseDec) * cos(degreesToRadians(riseH)));
  double seth = asin(sin(lat) * sin(setDec) +
      cos(lat) * cos(setDec) * cos(degreesToRadians(setH)));

  double deltaMtransit = -(transH / 360);

  double deltaMrise = (radToDeg(riseh) - h0) /
      (360 * cos(riseDec) * cos(lat) * sin(degreesToRadians(riseH)));
  double deltaMset = (radToDeg(seth) - h0) /
      (360 * cos(setDec) * cos(lat) * sin(degreesToRadians(setH)));

  transH += deltaMtransit;
  rise += deltaMrise;
  set += deltaMset;

  List<double> rad = [0, 0, 0];

  switch (planet) {
    case 0:
      year += 0.00555555556;
      break;
    case 1:
      //rad = Vsop87aMicro.getMercury(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 2:
      //rad = Vsop87aMicro.getVenus(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 3:
      rad = Vsop87aMicro.getEarth(jd2et(year));

      break;
    case 4:
      //rad = Vsop87aMicro.getMars(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 5:
      //rad = Vsop87aMicro.getJupiter(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 6:
      //rad = Vsop87aMicro.getSaturn(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 7:
      //rad = Vsop87aMicro.getUranus(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 8:
      //rad = Vsop87aMicro.getNeptune(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEarth(jd2et(year)), planet - 1, year);
      break;
    case 9:
    //rad = Vsop87aMicro.getNeptune(jd2et(year));
      rad = getBodyLightAdjusted(
          Vsop87aMicro.getEmb(jd2et(year)), planet - 1, year);
      break;
  }

  List<double> rad2 = cartesianToEclipticCoordinates(
      helioToGeo(rad, Vsop87aMicro.getEarth(jd2et(year))));

  List<double> altaz = raDecToAltAz(rad2[0], rad2[1], lat, -L, year);



  //print(altaz);

  return [
    constrain(transit) * 24.0,
    constrain(rise) * 24.0,
    constrain(set) * 24.0,
    radToDeg(altaz[0]),
    radToDeg(altaz[1]),
  ];

  //return [constrain(m0) * 24, constrain(m1) * 24, constrain(m2) * 24];
}
