part of curve_editor;

typedef Sprite = GSprite;
typedef Point = GPoint;

class AbsSprite extends GSprite {
  double w = 0;
  double h = 0;

  AbsSprite([this.w = 0, this.h = 0]);

  @override
  void addedToStage() {
    invalidateDraw();
  }

  void setSize(double w, double h) {
    if (w != this.w || h != this.h) {
      this.w = w;
      this.h = h;
      draw();
    }
  }

  void invalidateDraw() {
    if (!GTween.isTweening(validateDraw)) {
      dly(validateDraw);
    }
  }

  void validateDraw() {
    kill(validateDraw);
    draw();
  }

  // override
  void draw() {}
}

extension SpriteExt on GSprite {
  double get sw => stage!.stageWidth;

  double get sh => stage!.stageHeight;

  void kill(Object target) {
    GTween.killTweensOf(target);
  }

  void dly(Function callback, [double time = 0.0, bool killPrevious = true]) {
    if (killPrevious) {
      kill(callback);
    }
    GTween.delayedCall(time, callback);
  }
}

GRect bezierMinMax(double x0, double y0, double x1, double y1, double x2,
    double y2, double x3, double y3) {
  const _min = 0.000000000001;
  var tvalues = <double>[];
  double a;
  double b;
  double c;
  double t;
  double t1;
  double t2;
  double b2ac;
  double sqrtb2ac;
  for (var i = 0; i < 2; ++i) {
    if (i == 0) {
      b = 6 * x0 - 12 * x1 + 6 * x2;
      a = -3 * x0 + 9 * x1 - 9 * x2 + 3 * x3;
      c = 3 * x1 - 3 * x0;
    } else {
      b = 6 * y0 - 12 * y1 + 6 * y2;
      a = -3 * y0 + 9 * y1 - 9 * y2 + 3 * y3;
      c = 3 * y1 - 3 * y0;
    }
    if (Math.abs(a) < _min) {
      if (Math.abs(b) < _min) {
        continue;
      }
      t = -c / b;
      if (0 < t && t < 1) {
        tvalues.add(t);
      }
      continue;
    }
    b2ac = b * b - 4 * c * a;
    if (b2ac < 0) {
      if (Math.abs(b2ac) < _min) {
        t = -b / (2 * a);
        if (0 < t && t < 1) {
          tvalues.add(t);
        }
      }
      continue;
    }
    sqrtb2ac = Math.sqrt(b2ac);
    t1 = (-b + sqrtb2ac) / (2 * a);
    if (0 < t1 && t1 < 1) {
      tvalues.add(t1);
    }
    t2 = (-b - sqrtb2ac) / (2 * a);
    if (0 < t2 && t2 < 1) {
      tvalues.add(t2);
    }
  }
  final len = tvalues.length + 2;
  var xvalues = List<double>.filled(len, 0.0);
  var yvalues = List<double>.filled(len, 0.0);
  var j = tvalues.length;
  double mt = 0;
  while (j-- > 0) {
    t = tvalues[j];
    mt = 1 - t;
    xvalues[j] = (mt * mt * mt * x0) +
        (3 * mt * mt * t * x1) +
        (3 * mt * t * t * x2) +
        (t * t * t * x3);
    yvalues[j] = (mt * mt * mt * y0) +
        (3 * mt * mt * t * y1) +
        (3 * mt * t * t * y2) +
        (t * t * t * y3);
  }
  xvalues[len - 2] = x0;
  xvalues[len - 1] = x3;
  yvalues[len - 2] = y0;
  yvalues[len - 1] = y3;
  final rect = GRect(xvalues.reduce(Math.min), yvalues.reduce(Math.min));
  rect.right = xvalues.reduce(Math.max);
  rect.bottom = yvalues.reduce(Math.max);
  return rect;
  // return [
  //   xvalues.reduce(Math.min),
  //   yvalues.reduce(Math.min),
  //   xvalues.reduce(Math.max),
  //   yvalues.reduce(Math.max),
  // ];

  // return {
  //   min: {x: Math.min.apply(0, xvalues), y: Math.min.apply(0, yvalues)},
  //   max: {x: Math.max.apply(0, xvalues), y: Math.max.apply(0, yvalues)}
  // };
}
