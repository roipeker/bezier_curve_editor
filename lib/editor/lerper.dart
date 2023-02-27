///
/// roipeker, 2022
///
///
/// `Lerper` gist is  a collection of useful functions to make your own
/// tweens based on time/ratio/fraction.
///
/// Almost all methods are exposed as extension methods on `double`. So
/// you basically modify 1 number into a target value, making super simple
/// to chain transformations.
///
/// It also contains a basic CurvePath class to define a path of segments
/// of different types (linear, quadratic, cubic) and to get the value
/// at a given ratio (0-1). This can be used to create a motion path or
/// as a complex easing function to interpolate a single value over time.
///
/// Example:
///
///  ```dart
///  // counter as a frame counter...
///  var frames = 0;
///  void onTick(){
///    // ratio of 120 ticks (2 seconds if 60fps).
///    // [wrapLerp()] is a method that will return a value between 0 and 1,
///    // looping the value every 120 frames.
///    // It also takes a "start" value, that will work as a "delay" to
///    // the wrap interpolation, clamping `t` to 0.
///    var t = ++frames.wrapLerp(120)
///    // `x` will interpolate during 120 frames between 10 and 400 using
///    // sineOut curve.
///    var x = t.sineOut().lerp(10, 400);
///    // draw something with `x`
///  }
///  ```
///
/// ====

import 'dart:developer' as dev;
import 'dart:math' as math;

/// The path is defined by a start value and a list of segments.
/// Each segment is a linear or a curve.
/// Each segment starts at the end of the previous segment.
/// You can add segments to the path using the
/// line, quadraticBezier, and cubicBezier methods.
/// Use [transform( ratio )] to get the value at a given ratio (0-1).
class CurvePath {
  late double start;
  final _segments = <Segment>[];
  int _pathLength = 0;
  double _totalStrength = 0.0;

  CurvePath(this.start);

  /// Get the path data as a list of numbers, to be stored
  /// or serialized.
  List<num> get path {
    final out = <num>[start];
    for (var seg in _segments) {
      if (seg is LinearSegment) {
        out.addAll([1, seg.end, seg.strength]);
      } else if (seg is QuadraticBezierSegment) {
        out.addAll([2, seg.end, seg.strength, seg.control]);
      } else if (seg is CubicBezierSegment) {
        out.addAll([3, seg.end, seg.strength, seg.control1, seg.control2]);
      } else {
        dev.log("Segment not implemented.");
      }
    }
    return out;
  }

  /// Sets the path data from a list of numbers.
  set path(List<num> value) {
    clear();
    start = value[0].toDouble();
    var i = 1;
    while (i < value.length) {
      switch (value[i]) {
        case 1:
          _addSegment(LinearSegment(value[i + 1] + .0, value[i + 2] + .0));
          i += 3;
          break;
        case 2:
          _addSegment(
            QuadraticBezierSegment(
              value[i + 1] + .0,
              value[i + 2] + .0,
              value[i + 3] + .0,
            ),
          );
          i += 4;
          break;
        case 3:
          _addSegment(
            CubicBezierSegment(value[i + 1] + .0, value[i + 2] + .0,
                value[i + 3] + .0, value[i + 4] + .0),
          );
          i += 5;
          break;
        default:
          dev.log("Segment not implemented.");
      }
    }
  }

  /// is the path empty?
  bool isConstant() => _pathLength == 0;

  void _addSegment(Segment segment) {
    _segments.add(segment);
    _pathLength++;
    _totalStrength += segment.strength;
  }

  /// Starts a path at the given position creating a line to [end].
  /// [strength] defines a multiplier for the segment weight, used
  /// in transform() when the segments are not equally distributed.
  static CurvePath createLine(double end, [double strength = 1]) =>
      CurvePath(0).line(end, strength);

  /// Adds a linear segment to the path.
  CurvePath line(double end, [double strength = 1]) {
    _addSegment(LinearSegment(end, strength));
    return this;
  }

  /// Adds a quadratic bezier segment to the path.
  CurvePath quadraticBezier(double end, double control, [double strength = 1]) {
    _addSegment(QuadraticBezierSegment(end, strength, control));
    return this;
  }

  /// Adds a cubic bezier segment to the path.
  CurvePath cubicBezier(double end, double control1, double control2,
      [double strength = 1]) {
    _addSegment(CubicBezierSegment(end, strength, control1, control2));
    return this;
  }

  /// Get the last value of the path
  double getEnd() =>
      (_pathLength > 0) ? _segments[_pathLength - 1].end : double.nan;

  /// Get the value of the path at the given [rate] ratio.
  double transform(double rate) {
    double r = start;
    if (_pathLength == 1) {
      r = _segments[0].transform(start, rate);
    } else if (_pathLength > 1) {
      double ratio = rate * _totalStrength;
      double lastEnd = start;
      for (final path in _segments) {
        if (ratio > path.strength) {
          ratio -= path.strength;
          lastEnd = path.end;
        } else {
          r = path.transform(lastEnd, ratio / path.strength);
          break;
        }
      }
    }
    return r;
  }

  /// clears the segments in the path.
  void clear() {
    _pathLength = 0;
    _totalStrength = 0;
    _segments.clear();
  }
}

class Segment {
  final double end, strength;

  const Segment(this.end, this.strength);

  double transform(double start, double delta) => double.nan;
}

class LinearSegment extends Segment {
  const LinearSegment(super.end, super.strength);

  @override
  double transform(double start, double delta) => start + delta * (end - start);
}

class QuadraticBezierSegment extends Segment {
  final double control;

  const QuadraticBezierSegment(super.end, super.strength, this.control);

  @override
  double transform(double start, double delta) {
    final inv = 1 - delta;
    return inv * inv * start + 2 * inv * delta * control + delta * delta * end;
  }
}

class CubicBezierSegment extends Segment {
  final double control1, control2;

  const CubicBezierSegment(
    super.end,
    super.strength,
    this.control1,
    this.control2,
  );

  @override
  double transform(double start, double delta) {
    final inv = 1 - delta;
    final inv2 = inv * inv;
    final d2 = delta * delta;
    return inv2 * inv * start +
        3 * inv2 * delta * control1 +
        3 * inv * d2 * control2 +
        d2 * delta * end;
  }
}

abstract class EasingTools {
  @pragma('vm:prefer-inline')
  static const pi = 3.1415926535897932384626433832795;
  @pragma('vm:prefer-inline')
  static const piHalf = pi / 2;
  static const pi2 = pi * 2;
  @pragma('vm:prefer-inline')
  static const ln2 = 0.6931471805599453;
  @pragma('vm:prefer-inline')
  static const ln2_10 = 6.931471805599453;

  // === LINEAR ===
  @pragma('vm:prefer-inline')
  static double linear(double t) => t;

  // === SINE ===
  @pragma('vm:prefer-inline')
  static double sineIn(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    return 1 - math.cos(t * pi / 2);
  }

  @pragma('vm:prefer-inline')
  static double sineOut(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.sin(t * piHalf);
  }

  @pragma('vm:prefer-inline')
  static double sineInOut(double t) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else {
      return -0.5 * (math.cos(pi * t) - 1);
    }
  }

  @pragma('vm:prefer-inline')
  static double sineOutIn(double t) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else if (t < 0.5) {
      return 0.5 * math.sin((t * 2) * piHalf);
    } else {
      return -0.5 * math.cos((t * 2 - 1) * piHalf) + 1;
    }
  }

  /// === QUAD ===
  @pragma('vm:prefer-inline')
  static double quadIn(double t) => t * t;

  @pragma('vm:prefer-inline')
  static double quadOut(double t) => -t * (t - 2);

  @pragma('vm:prefer-inline')
  static double quadInOut(double t) =>
      (t < .5) ? t * t * 2 : (-2 * t * (t - 2) - 1);

  @pragma('vm:prefer-inline')
  static double quadOutIn(double t) {
    return (t < 0.5)
        ? -0.5 * (t = (t * 2)) * (t - 2)
        : 0.5 * (t = (t * 2 - 1)) * t + 0.5;
  }

  /// === CUBIC ===
  @pragma('vm:prefer-inline')
  static double cubicIn(double t) => t * t * t;

  @pragma('vm:prefer-inline')
  static double cubicOut(double t) {
    return (--t) * t * t + 1;
    // t--;
    // return t * t * t + 1;
  }

  @pragma('vm:prefer-inline')
  static double cubicInOut(double t) {
    // t *= 2;
    // if (t < 1) {
    //   return 0.5 * t * t * t;
    // }
    // t -= 2;
    // return 0.5 * (t * t * t + 2);
    return ((t *= 2) < 1) ? 0.5 * t * t * t : 0.5 * ((t -= 2) * t * t + 2);
  }

  @pragma('vm:prefer-inline')
  static double cubicOutIn(double t) {
    return 0.5 * ((t = t * 2 - 1) * t * t + 1);
  }

  /// === QUART ===
  @pragma('vm:prefer-inline')
  static double quartIn(double t) => (t *= t) * t;

  @pragma('vm:prefer-inline')
  static double quartOut(double t) => 1 - (t = (t = t - 1) * t) * t;

  @pragma('vm:prefer-inline')
  static double quartInOut(double t) {
    return ((t *= 2) < 1)
        ? 0.5 * (t *= t) * t
        : -0.5 * ((t = (t -= 2) * t) * t - 2);
  }

  @pragma('vm:prefer-inline')
  static double quartOutIn(double t) {
    return (t < 0.5)
        ? -0.5 * (t = (t = t * 2 - 1) * t) * t + 0.5
        : 0.5 * (t = (t = t * 2 - 1) * t) * t + 0.5;
  }

  /// === QUINT ===
  @pragma('vm:prefer-inline')
  static double quintIn(double t) {
    return t * (t *= t) * t;
    // return t * t * t * t * t ;
  }

  @pragma('vm:prefer-inline')
  static double quintOut(double t) => (t = t - 1) * (t *= t) * t + 1;

  @pragma('vm:prefer-inline')
  static double quintInOut(double t) {
    return ((t *= 2) < 1)
        ? 0.5 * t * (t *= t) * t
        : 0.5 * (t -= 2) * (t *= t) * t + 1;
  }

  @pragma('vm:prefer-inline')
  static double quintOutIn(double t) =>
      0.5 * ((t = t * 2 - 1) * (t *= t) * t + 1);

  /// === EXPONENTIAL ===
  /// Uses pow() or Logarithmic Curve.
  @pragma('vm:prefer-inline')
  static double expoIn(double t) {
    // return math.pow(2, 10 * (t - 1)).toDouble();
    return t == 0 ? 0 : math.exp(ln2_10 * (t - 1));
  }

  @pragma('vm:prefer-inline')
  static double expoOut(double t) {
    return t == 1 ? 1 : (1 - math.exp(-ln2_10 * t));
  }

  @pragma('vm:prefer-inline')
  static double expoInOut(double t) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else if ((t *= 2) < 1) {
      return 0.5 * math.exp(ln2_10 * (t - 1));
    } else {
      return 0.5 * (2 - math.exp(-ln2_10 * (t - 1)));
    }
  }

  @pragma('vm:prefer-inline')
  static double expoOutIn(double t) {
    if (t < 0.5) {
      return 0.5 * (1 - math.exp(-20 * ln2 * t));
    } else if (t == 0.5) {
      return 0.5;
    } else {
      return 0.5 * (math.exp(20 * ln2 * (t - 1)) + 1);
    }
  }

  /// === CIRCULAR ===
  // static double circIn(double t) => 1 - math.sqrt(1 - t * t);
  // public static inline function circIn(t:Float):Float {
  @pragma('vm:prefer-inline')
  static double circIn(double t) {
    if (t < -1 || 1 < t) {
      return 0;
    } else {
      return 1 - math.sqrt(1 - t * t);
    }
  }

  @pragma('vm:prefer-inline')
  static double circOut(double t) {
    if (t < 0 || 2 < t) {
      return 0;
    } else {
      return math.sqrt(t * (2 - t));
    }
  }

  @pragma('vm:prefer-inline')
  static double circInOut(double t) {
    if (t < -0.5 || 1.5 < t) {
      return 0.5;
    } else if ((t *= 2) < 1) {
      return -0.5 * (math.sqrt(1 - t * t) - 1);
    } else {
      return 0.5 * (math.sqrt(1 - (t -= 2) * t) + 1);
    }
  }

  @pragma('vm:prefer-inline')
  static double circOutIn(double t) {
    if (t < 0) {
      return 0;
    } else if (1 < t) {
      return 1;
    } else if (t < 0.5) {
      return 0.5 * math.sqrt(1 - (t = t * 2 - 1) * t);
    } else {
      return -0.5 * ((math.sqrt(1 - (t = t * 2 - 1) * t) - 1) - 1);
    }
  }

  /// === bounce ===
  @pragma('vm:prefer-inline')
  static double bounceIn(double t) {
    if ((t = 1 - t) < (1 / 2.75)) {
      return 1 - ((7.5625 * t * t));
    } else if (t < (2 / 2.75)) {
      return 1 - ((7.5625 * (t -= (1.5 / 2.75)) * t + 0.75));
    } else if (t < (2.5 / 2.75)) {
      return 1 - ((7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375));
    } else {
      return 1 - ((7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375));
    }
  }

  @pragma('vm:prefer-inline')
  static double bounceOut(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
      return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
      return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
    // if (t < (1 / 2.75)) {
    //   return (7.5625 * t * t);
    // } else if (t < (2 / 2.75)) {
    //   return (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75);
    // } else if (t < (2.5 / 2.75)) {
    //   return (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375);
    // } else {
    //   return (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375);
    // }
  }

  @pragma('vm:prefer-inline')
  static double bounceInOut(double t) {
    if (t < 0.5) {
      if ((t = (1 - t * 2)) < (1 / 2.75)) {
        return (1 - ((7.5625 * t * t))) * 0.5;
      } else if (t < (2 / 2.75)) {
        return (1 - ((7.5625 * (t -= (1.5 / 2.75)) * t + 0.75))) * 0.5;
      } else if (t < (2.5 / 2.75)) {
        return (1 - ((7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375))) * 0.5;
      } else {
        return (1 - ((7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375))) * 0.5;
      }
    } else {
      if ((t = (t * 2 - 1)) < (1 / 2.75)) {
        return ((7.5625 * t * t)) * 0.5 + 0.5;
      } else if (t < (2 / 2.75)) {
        return ((7.5625 * (t -= (1.5 / 2.75)) * t + 0.75)) * 0.5 + 0.5;
      } else if (t < (2.5 / 2.75)) {
        return ((7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375)) * 0.5 + 0.5;
      } else {
        return ((7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375)) * 0.5 + 0.5;
      }
    }
  }

  @pragma('vm:prefer-inline')
  static double bounceOutIn(double t) {
    if (t < 0.5) {
      if ((t = (t * 2)) < (1 / 2.75)) {
        return 0.5 * (7.5625 * t * t);
      } else if (t < (2 / 2.75)) {
        return 0.5 * (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75);
      } else if (t < (2.5 / 2.75)) {
        return 0.5 * (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375);
      } else {
        return 0.5 * (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375);
      }
    } else {
      if ((t = (1 - (t * 2 - 1))) < (1 / 2.75)) {
        return 0.5 - (0.5 * (7.5625 * t * t)) + 0.5;
      } else if (t < (2 / 2.75)) {
        return 0.5 - (0.5 * (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75)) + 0.5;
      } else if (t < (2.5 / 2.75)) {
        return 0.5 - (0.5 * (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375)) + 0.5;
      } else {
        return 0.5 -
            (0.5 * (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375)) +
            0.5;
      }
    }
  }

  /// === BACK easing ===

  static const double defaultOvershoot = 1.70158;

  @pragma('vm:prefer-inline')
  static double backIn(double t, [double c1 = EasingTools.defaultOvershoot]) {
    // if (t == 0) {
    //   return 0;
    // } else if (t == 1) {
    //   return 1;
    // } else {
    //   return t * t * ((overshoot + 1) * t - overshoot);
    // }
    final c3 = c1 + 1;
    return c3 * t * t * t - c1 * t * t;
  }

  @pragma('vm:prefer-inline')
  static double backOut(double t, [double c1 = EasingTools.defaultOvershoot]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else {
      return ((t = t - 1) * t * ((c1 + 1) * t + c1) + 1);
    }
  }

  @pragma('vm:prefer-inline')
  static double backInOut(double t,
      [double c1 = EasingTools.defaultOvershoot]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else if ((t *= 2) < 1) {
      return 0.5 * (t * t * (((c1 * 1.525) + 1) * t - c1 * 1.525));
    } else {
      return 0.5 * ((t -= 2) * t * (((c1 * 1.525) + 1) * t + c1 * 1.525) + 2);
    }
  }

  @pragma('vm:prefer-inline')
  static double backOutIn(double t,
      [double c1 = EasingTools.defaultOvershoot]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else if (t < 0.5) {
      return 0.5 * ((t = t * 2 - 1) * t * ((c1 + 1) * t + c1) + 1);
    } else {
      return 0.5 * (t = t * 2 - 1) * t * ((c1 + 1) * t - c1) + 0.5;
    }
  }

  /// === ELASTIC easing ===

  static const double defaultAmplitude = 1;
  static const double defaultPeriod = 0.0003;

  @pragma('vm:prefer-inline')
  static double elasticIn(
    double t, [
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else {
      var s = period / 4;
      return -(amplitude *
          math.exp(ln2_10 * (t -= 1)) *
          math.sin((t * 0.001 - s) * (2 * pi) / period));
    }
  }

  @pragma('vm:prefer-inline')
  static double elasticOut(
    double t, [
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else {
      var s = period / 4;
      return amplitude *
              math.exp(-ln2_10 * t) *
              math.sin((t * 0.001 - s) * (2 * pi) / period) +
          1;
    }
  }

  @pragma('vm:prefer-inline')
  static double elasticInOut(double t,
      [double period = EasingTools.defaultPeriod,
      double amplitude = EasingTools.defaultAmplitude]) {
    if (t == 0) {
      return 0;
    } else if (t == 1) {
      return 1;
    } else {
      var s = period / 4;
      if ((t *= 2) < 1) {
        return -0.5 *
            (amplitude *
                math.exp(ln2_10 * (t -= 1)) *
                math.sin((t * 0.001 - s) * pi2 / period));
      } else {
        return amplitude *
                math.exp(-ln2_10 * (t -= 1)) *
                math.sin((t * 0.001 - s) * pi2 / period) *
                0.5 +
            1;
      }
    }
  }

  @pragma('vm:prefer-inline')
  static double elasticOutIn(double t,
      [double period = EasingTools.defaultPeriod,
      double amplitude = EasingTools.defaultAmplitude]) {
    if (t < 0.5) {
      if ((t *= 2) == 0) {
        return 0;
      } else {
        var s = period / 4;
        return (amplitude / 2) *
                math.exp(-ln2_10 * t) *
                math.sin((t * 0.001 - s) * pi2 / period) +
            0.5;
      }
    } else {
      if (t == 0.5) {
        return 0.5;
      } else if (t == 1) {
        return 1;
      } else {
        t = t * 2 - 1;
        var s = period / 4;
        return -((amplitude / 2) *
                math.exp(ln2_10 * (t -= 1)) *
                math.sin((t * 0.001 - s) * pi2 / period)) +
            0.5;
      }
    }
  }

  @pragma('vm:prefer-inline')
  static double warpOut(double t) => t <= 0 ? 0 : 1;

  @pragma('vm:prefer-inline')
  static double warpIn(double t) => t < 1 ? 0 : 1;

  @pragma('vm:prefer-inline')
  static double warpInOut(double t) => t < .5 ? 0 : 1;

  @pragma('vm:prefer-inline')
  static double warpOutIn(double t) {
    if (t <= 0) {
      return 0;
    } else if (t < 1) {
      return .5;
    }
    return 1;
  }
}

abstract class LerpTools {
  static final _rnd = math.Random();

  @pragma('vm:prefer-inline')
  static double spread(double rate, double scale) => lerp(rate, -scale, scale);

  @pragma('vm:prefer-inline')
  static double shake(
    double rate, [
    double center = 0,
    double Function()? randomCallback,
  ]) =>
      center + spread((randomCallback ?? _rnd.nextDouble)(), rate);

  @pragma('vm:prefer-inline')
  static double sin(double rate) => math.sin(rate * EasingTools.pi2);

  @pragma('vm:prefer-inline')
  static double cos(double rate) => math.cos(rate * EasingTools.pi2);

  @pragma('vm:prefer-inline')
  static double revert(double rate) => 1 - rate;

  /* Clamps a `value` between `min` and `max`. */
  static double clamp(double value, [double min = 0.0, double max = 1.0]) {
    if (value <= min) {
      return min;
    } else if (value >= max) {
      return max;
    } else {
      return value;
    }
  }

  @pragma('vm:prefer-inline')
  static double lerp(num rate, num from, num to) =>
      from * (1.0 - rate) + to * rate.toDouble();

  @pragma('vm:prefer-inline')
  static double inverseLerp(num value, num from, num to) =>
      (value - from) / (to - from);

  @pragma('vm:prefer-inline')
  static double mixEasing(
    double rate,
    EaseFun easing1,
    EaseFun easing2, [
    double easing2Strength = 0.5,
  ]) =>
      easing2Strength.lerp(easing1(rate), easing2(rate));

  @pragma('vm:prefer-inline')
  static double crossfadeEasing(
    double rate,
    EaseFun easing1,
    EaseFun easing2,
    EaseFun easing2StrengthEasing, [
    double easing2StrengthStart = 0,
    double easing2StrengthEnd = 1,
  ]) =>
      easing2StrengthEasing(rate)
          .lerp(easing2StrengthStart, easing2StrengthEnd)
          .lerp(easing1(rate), easing2(rate));

  @pragma('vm:prefer-inline')
  static double connectEasing(
    double time,
    EaseFun easing1,
    EaseFun easing2, [
    double switchTime = 0.5,
    double switchValue = 0.5,
  ]) =>
      (time < switchTime)
          ? //
          easing1(time.invLerp(0, switchTime)).lerp(0, switchValue)
          : //
          easing2(time.invLerp(switchTime, 1)).lerp(switchValue, 1);

  @pragma('vm:prefer-inline')
  static double yoyo(double rate, EaseFun ease) =>
      (rate < 0.5) ? ease(rate * 2) : ease((1 - rate) * 2);

  @pragma('vm:prefer-inline')
  static double reverse(double rate, EaseFun ease) =>
      (rate < 0.5) ? ease(rate * 2) : (1 - ease((rate - .5) * 2));

  /// quadratic
  @pragma('vm:prefer-inline')
  static double bezier2(double rate, double from, double control, double to) =>
      lerp(rate, lerp(rate, from, control), lerp(rate, control, to));

  @pragma('vm:prefer-inline')
  static double _evaluateCubic(double a, double b, double m) =>
      3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;

  /// Flutter's `Cubic`.
  @pragma('vm:prefer-inline')
  static double cubic(double rate, double a, double b, double c, double d,
      [double resolution = .001]) {
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final double midpoint = (start + end) / 2;
      final double estimate = _evaluateCubic(a, c, midpoint);
      if ((rate - estimate).abs() < resolution) {
        return _evaluateCubic(b, d, midpoint);
      }
      if (estimate < rate) {
        start = midpoint;
      } else {
        end = midpoint;
      }
    }
  }

  /// cubic
  @pragma('vm:prefer-inline')
  static double bezier3(
    double rate,
    double from,
    double control1,
    double control2,
    double to,
  ) =>
      bezier2(
        rate,
        lerp(rate, from, control1),
        lerp(rate, control1, control2),
        lerp(rate, control2, to),
      );

  @pragma('vm:prefer-inline')
  static double bezier(double rate, Iterable<double> values) {
    if (values.length < 2) {
      throw "points length must be more than 2";
    } else if (values.length == 2) {
      return lerp(rate, values.first, values.last);
    } else if (values.length == 3) {
      return bezier2(rate, values.first, values.elementAt(1), values.last);
    } else {
      return _bezier(rate, values);
    }
  }

  static double _bezier(double rate, Iterable<double> values) {
    if (values.length == 4) {
      return bezier3(rate, values.first, values.elementAt(1),
          values.elementAt(2), values.last);
    }
    final iterValues = values.toList(growable: false);
    final newLen = values.length - 1;
    final output = List.filled(values.length - 1, 0.0);
    for (var i = 0; i < newLen; ++i) {
      output[i] = lerp(rate, iterValues[i], iterValues[i + 1]);
    }
    return _bezier(rate, output);
  }

  static double uniformQuadBSpline(double rate, Iterable<double> values) {
    if (values.length < 2) {
      throw "points length must be more than 2";
    }
    if (values.length == 2) {
      return lerp(rate, values.first, values.last);
    }
    final max = values.length - 2;
    final scaledRate = rate * max;
    final index = scaledRate.floor().clamp(0, max - 1);
    final innerRate = scaledRate - index;
    final p0 = values.elementAt(index);
    final p1 = values.elementAt(index + 1);
    final p2 = values.elementAt(index + 2);
    return innerRate * innerRate * (p0 / 2 - p1 + p2 / 2) +
        innerRate * (-p0 + p1) +
        p0 / 2;
  }

  @pragma('vm:prefer-inline')
  static double polyline(double rate, List<double> values) {
    if (values.length < 2) {
      throw "points length must be more than 2";
    } else {
      final max = values.length - 1;
      final scaledRate = rate * max;
      final index = scaledRate.clamp(0, max - 1).floor();
      return lerp(scaledRate - index, values[index], values[index + 1]);
    }
  }
}

typedef EaseFun = double Function(double rate);

extension DoubleTween on double {
  double sinRate() => LerpTools.sin(this);

  double cosRate() => LerpTools.cos(this);

  double revert() => LerpTools.revert(clamped(0, 1));

  double sineIn() => EasingTools.sineIn(this);

  double sineOut() => EasingTools.sineOut(this);

  double sineInOut() => EasingTools.sineInOut(this);

  double sineOutIn() => EasingTools.sineOutIn(this);

  double quadIn() => EasingTools.quadIn(this);

  double quadOut() => EasingTools.quadOut(this);

  double quadInOut() => EasingTools.quadInOut(this);

  double quadOutIn() => EasingTools.quadOutIn(this);

  double cubicIn() => EasingTools.cubicIn(this);

  double cubicOut() => EasingTools.cubicOut(this);

  double cubicInOut() => EasingTools.cubicInOut(this);

  double cubicOutIn() => EasingTools.cubicOutIn(this);

  double quintIn() => EasingTools.quintIn(this);

  double quintOut() => EasingTools.quintOut(this);

  double quintInOut() => EasingTools.quintInOut(this);

  double quintOutIn() => EasingTools.quintOutIn(this);

  double expoIn() => EasingTools.expoIn(this);

  double expoOut() => EasingTools.expoOut(this);

  double expoInOut() => EasingTools.expoInOut(this);

  double expoOutIn() => EasingTools.expoOutIn(this);

  double circIn() => EasingTools.circIn(this);

  double circOut() => EasingTools.circOut(this);

  double circInOut() => EasingTools.circInOut(this);

  double circOutIn() => EasingTools.circOutIn(this);

  double bounceIn() => EasingTools.bounceIn(this);

  double bounceOut() => EasingTools.bounceOut(this);

  double bounceInOut() => EasingTools.bounceInOut(this);

  double bounceOutIn() => EasingTools.bounceOutIn(this);

  double backIn() => EasingTools.backIn(this);

  double backOut() => EasingTools.backOut(this);

  double backInOut() => EasingTools.backInOut(this);

  double backOutIn() => EasingTools.backOutIn(this);

  double elasticIn([
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) =>
      EasingTools.elasticIn(
        this,
        period,
        amplitude,
      );

  double elasticOut([
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) =>
      EasingTools.elasticOut(
        this,
        period,
        amplitude,
      );

  double elasticInOut([
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) =>
      EasingTools.elasticInOut(
        this,
        period,
        amplitude,
      );

  double elasticOutIn([
    double period = EasingTools.defaultPeriod,
    double amplitude = EasingTools.defaultAmplitude,
  ]) =>
      EasingTools.elasticOutIn(
        this,
        period,
        amplitude,
      );

  double warpIn() => EasingTools.warpIn(this);

  double warpOut() => EasingTools.warpOut(this);

  double warpInOut() => EasingTools.warpInOut(this);

  double warpOutIn() => EasingTools.warpOutIn(this);

  double shake([
    double center = 0,
    double Function()? randomCallback,
  ]) =>
      LerpTools.shake(this, center, randomCallback);

  double lerp(num from, num to) {
    return LerpTools.lerp(this, from, to);
  }

  double invLerp(num from, num to) => LerpTools.inverseLerp(
        this,
        from,
        to,
      );

  /// To wrap a normalized value [lerp()] to a range.
  /// Useful to keep a "loop" during a time rate.
  /// For example...
  /// ```dart
  ///   var frame = 0;
  ///   onTick(){
  ///     // it will wait 20 frames, then run til frame 80.
  ///     // and wrap back (modulo) to 0, and wait 20 frames again...
  ///     var t = ++frame.wrapLerp(80, 20);
  ///     print(t);
  ///   }
  ///
  double wrapLerp(num end, [num start = 0, bool clamped = true]) {
    var value = LerpTools.inverseLerp(this % end, start, end);
    if (clamped) {
      value = value.clamped(0, 1);
    }
    return value;
  }

  // used to set bounds to wrapped normalized values.
  // for example, set a delay (start) and duration (end).
  // based on a rate (wrappedRate)  previously
  // wrapped by [wrapLerp()].
  // use [validLerp()] to check if the result is in valid range
  // (0-1).
  @pragma('vm:prefer-inline')
  double invWrapLerp(num wrappedRate, num start, num end, [bool clamp = true]) {
    final result = invLerp(start / wrappedRate, end / wrappedRate);
    return clamp ? result.clamped(0, 1) : result;
  }

  /// To repeat x [times] a normalized value [lerp()].
  /// Can be chained with [reverse()] and [yoyo()].
  double repeatLerp(double times) {
    final invRepeat = 1 / times;
    return (this % invRepeat).invLerp(0, invRepeat);
  }

  @pragma('vm:prefer-inline')
  double clamped(double min, double max) => LerpTools.clamp(this, min, max);

  // to use in if() statement
  @pragma('vm:prefer-inline')
  bool validLerp() => this >= 0 && this <= 1;

  @pragma('vm:prefer-inline')
  double mixEase(EaseFun ease1, EaseFun ease2, [double strength = 0.5]) {
    return LerpTools.mixEasing(this, ease1, ease2, strength);
  }

  @pragma('vm:prefer-inline')
  double yoyo([EaseFun ease = EasingTools.linear]) =>
      LerpTools.yoyo(this, ease);

  @pragma('vm:prefer-inline')
  double reverse([EaseFun ease = EasingTools.linear]) =>
      LerpTools.reverse(this, ease);

  @pragma('vm:prefer-inline')
  double connectEasing(
    EaseFun easing1,
    EaseFun easing2, [
    double switchTime = 0.5,
    double switchValue = 0.5,
  ]) {
    return LerpTools.connectEasing(
        this, easing1, easing2, switchTime, switchValue);
  }

  @pragma('vm:prefer-inline')
  double crossfadeEasing(
    EaseFun easing1,
    EaseFun easing2,
    EaseFun easing2StrengthEasing, [
    double easing2StrengthStart = 0,
    double easing2StrengthEnd = 1,
  ]) =>
      LerpTools.crossfadeEasing(
        this,
        easing1,
        easing2,
        easing2StrengthEasing,
        easing2StrengthStart,
        easing2StrengthEnd,
      );

  // quadratic
  @pragma('vm:prefer-inline')
  double bezier2(double from, double control, double to) =>
      LerpTools.bezier2(this, from, control, to);

  /// cubic easing.
  @pragma('vm:prefer-inline')
  double cubic(
    double from,
    double control1,
    double control2,
    double to, [
    double resolution = .001,
  ]) =>
      LerpTools.cubic(this, from, control1, control2, to, resolution);

  /// cubic
  @pragma('vm:prefer-inline')
  double bezier3(
    double from,
    double control1,
    double control2,
    double to,
  ) =>
      LerpTools.bezier3(this, from, control1, control2, to);

  double bezier(Iterable<double> points) => LerpTools.bezier(this, points);

  double bspline(Iterable<double> points) =>
      LerpTools.uniformQuadBSpline(this, points);

  double polyline(Iterable<double> points) =>
      LerpTools.polyline(this, points.toList(growable: false));
}

extension EaseInt on int {
  double lerp(num from, num to) => LerpTools.lerp(
        toDouble(),
        from.toDouble(),
        to.toDouble(),
      );

  double wrapLerp(num end, [num start = 0]) {
    return LerpTools.inverseLerp(this % end, start, end);
  }

  double shake([
    double center = 0,
    double Function()? randomCallback,
  ]) =>
      LerpTools.shake(toDouble(), center, randomCallback);

  double lerpInverse(num from, num to) => LerpTools.inverseLerp(
        toDouble(),
        from.toDouble(),
        to.toDouble(),
      );
}

// class GPointTools {
//   static GPoint polyline(double rate, List<GPoint> points, [GPoint? output]) {
//     output ??= GPoint(0,0);
//     var x = <double>[];
//     var y = <double>[];
//     for (var p in points) {
//       x.add(p.x);
//       y.add(p.y);
//     }
//     output.x = rate.polyline(x);
//     output.y = rate.polyline(y);
//     return output;
//   }
// }

/// expose constants easing functions for LerpTools functions like
/// [LerpTools.yoyo] and [LerpTools.reverse].

const linear = EasingTools.linear;
const sineIn = EasingTools.sineIn;
const sineOut = EasingTools.sineOut;
const sineInOut = EasingTools.sineInOut;
const sineOutIn = EasingTools.sineOutIn;

const quadIn = EasingTools.quadIn;
const quadOut = EasingTools.quadOut;
const quadInOut = EasingTools.quadInOut;
const quadOutIn = EasingTools.quadOutIn;

const cubicIn = EasingTools.cubicIn;
const cubicOut = EasingTools.cubicOut;
const cubicInOut = EasingTools.cubicInOut;
const cubicOutIn = EasingTools.cubicOutIn;

const quintIn = EasingTools.quintIn;
const quintOut = EasingTools.quintOut;
const quintInOut = EasingTools.quintInOut;
const quintOutIn = EasingTools.quintOutIn;

const expoIn = EasingTools.expoIn;
const expoOut = EasingTools.expoOut;
const expoInOut = EasingTools.expoInOut;
const expoOutIn = EasingTools.expoOutIn;

const circIn = EasingTools.circIn;
const circOut = EasingTools.circOut;
const circInOut = EasingTools.circInOut;
const circOutIn = EasingTools.circOutIn;

const bounceIn = EasingTools.bounceIn;
const bounceOut = EasingTools.bounceOut;
const bounceInOut = EasingTools.bounceInOut;
const bounceOutIn = EasingTools.bounceOutIn;

const backIn = EasingTools.backIn;
const backOut = EasingTools.backOut;
const backInOut = EasingTools.backInOut;
const backOutIn = EasingTools.backOutIn;

const elasticIn = EasingTools.elasticIn;
const elasticOut = EasingTools.elasticOut;
const elasticInOut = EasingTools.elasticInOut;
const elasticOutIn = EasingTools.elasticOutIn;

const warpIn = EasingTools.warpIn;
const warpOut = EasingTools.warpOut;
const warpInOut = EasingTools.warpInOut;
const warpOutIn = EasingTools.warpOutIn;

// Gives back an `EaseFun` callback transform, useful for [LerpTools.yoyo]
EaseFun easeCubic(double a, b, c, d) => (double rate) => rate.cubic(a, b, c, d);

// Make an instance with the configuration for a Cubic Bezier.
// useful for [LerpTools.yoyo].
// ```
//  double time = (getTimer() * .004);
//  final easeCubic = CubicParams(0.25, 0.1, 0.25, 1.0);
//  box.x = time.yoyo(easeCubic).lerp(0, 100);
// ```
class CubicParams {
  final double a, b, c, d;

  const CubicParams(this.a, this.b, this.c, this.d);

  double call(double rate) => rate.cubic(a, b, c, d);
}
