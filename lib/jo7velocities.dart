import 'dart:math';

class Vsop87aPicoVelocities {
  static void getEarth(double t, List<double> temp) {
    temp[0] = earthX(t) / 365250.0;
    temp[1] = earthY(t) / 365250.0;
    temp[2] = earthZ(t) / 365250.0;
  }

  static double earthX(double t) {
    double exp = 0.0;
    double earthX0 = 0.0;
    exp = 0;
    earthX0 += -pow(t, exp) *
        0.99982928844 *
        6283.07584999140 *
        sin(1.75348568475 + 6283.07584999140 * t);
    earthX0 += -pow(t, exp) *
        0.00835257300 *
        12566.15169998280 *
        sin(1.71034539450 + 12566.15169998280 * t);
    earthX0 += -pow(t, exp) *
        0.00561144206 *
        0.00000000000 *
        sin(0.00000000000 + 0.00000000000 * t);
    earthX0 += -pow(t, exp) *
        0.00010466628 *
        18849.22754997420 *
        sin(1.66722645223 + 18849.22754997420 * t);

    double earthX1 = 0.0;
    exp = 1;
    earthX1 += pow(t, exp - 1) *
        exp *
        (0.00123403056 * cos(0.00000000000 + 0.00000000000 * t) -
            pow(t, exp) *
                0.00123403056 *
                0.00000000000 *
                sin(0.00000000000 + 0.00000000000 * t));
    earthX1 += pow(t, exp - 1) *
        exp *
        (0.00051500156 * cos(6.00266267204 + 12566.15169998280 * t) -
            pow(t, exp) *
                0.00051500156 *
                12566.15169998280 *
                sin(6.00266267204 + 12566.15169998280 * t));

    return earthX0 + earthX1;
  }

  static double earthY(double t) {
    double exp = 0.0;
    double earthY0 = 0.0;
    exp = 0;
    earthY0 += -pow(t, exp) *
        0.99989211030 *
        6283.07584999140 *
        sin(0.18265890456 + 6283.07584999140 * t);
    earthY0 += -pow(t, exp) *
        0.02442699036 *
        0.00000000000 *
        sin(3.14159265359 + 0.00000000000 * t);
    earthY0 += -pow(t, exp) *
        0.00835292314 *
        12566.15169998280 *
        sin(0.13952878991 + 12566.15169998280 * t);
    earthY0 += -pow(t, exp) *
        0.00010466965 *
        18849.22754997420 *
        sin(0.09641690558 + 18849.22754997420 * t);

    double earthY1 = 0.0;
    exp = 1;
    earthY1 += pow(t, exp - 1) *
        exp *
        (0.00093046324 * cos(0.00000000000 + 0.00000000000 * t) -
            pow(t, exp) *
                0.00093046324 *
                0.00000000000 *
                sin(0.00000000000 + 0.00000000000 * t));
    earthY1 += pow(t, exp - 1) *
        exp *
        (0.00051506609 * cos(4.43180499286 + 12566.15169998280 * t) -
            pow(t, exp) *
                0.00051506609 *
                12566.15169998280 *
                sin(4.43180499286 + 12566.15169998280 * t));

    return earthY0 + earthY1;
  }

  static double earthZ(double t) {
    double exp = 0.0;
    double earthZ1 = 0.0;
    exp = 1;
    earthZ1 += pow(t, exp - 1) *
        exp *
        (0.00227822442 * cos(3.41372504278 + 6283.07584999140 * t) -
            pow(t, exp) *
                0.00227822442 *
                6283.07584999140 *
                sin(3.41372504278 + 6283.07584999140 * t));

    return earthZ1;
  }
}
