part of curve_editor;

class EditorCurveConfig {
  bool useStrengthHandler = true;

  bool get isMirrorHandler => !GKeyboard.isDown(GKey.shift);

  bool get isMirrorDir => GKeyboard.isDown(GKey.control);
}

class CurveEditor extends AbsSprite {
  final config = EditorCurveConfig();
  late GShape drawer;
  late GSprite handlerContainer;
  List<AnchorButton> buttons = [];

  bool useBBox = false;
  List<GRect> bboxes = [];
  bool _showHandlers = true;
  late CurvePath pathX, pathY;

  CurveEditor(super.w, super.h);

  @override
  void addedToStage() {
    super.addedToStage();
    drawer = addChild(GShape());
    handlerContainer = addChild(GSprite());
    pathX = CurvePath(0);
    pathY = CurvePath(0);
    createMainControls(7);
  }

  @override
  void update(double delta) {
    super.update(delta);
    const key = GKeyboard.justReleased;
    if (key(GKey.digit2)) {
      toggleControls();
    }
  }

  @override
  void draw() {
    /// update control bounds.
    for (var btn in buttons) {
      btn.dragBounds.width = w;
      btn.dragBounds.height = h;
      btn.updateStrengthBounds();
      btn.x = btn.x.clamp(0, w);
      btn.y = btn.y.clamp(0, h);
    }

    /// reposition ?
    graphics
        .clear()
        .lineStyle(0, Colors.white30)
        .drawRect(0, 0, w, h)
        .endFill();
  }

  void createMainControls(int count) {
    buttons.clear();
    double gap = w / (count - 1);
    double py = h / 2;
    for (var i = 0; i < count; ++i) {
      double px = i * gap;
      final button = addAnchor(i == 0, false, px, py);
      buttons.add(button);
    }
    updateCurve();
  }

  void updateCurve() {
    drawer.graphics.clear();
    handlerContainer.graphics.clear();

    final g = drawer.graphics;

    /// lines
    // g.lineStyle(1, Colors.white10);
    // for (var i = 0; i < buttons.length; ++i) {
    //   var btn = buttons[i];
    //   if (i == 0) {
    //     g.moveTo(btn.x, btn.y);
    //   } else {
    //     g.lineTo(btn.x, btn.y);
    //   }
    // }

    if (_showHandlers) {
      _drawHandlerLines();
      if (config.useStrengthHandler) {
        _drawStrengthLines();
      }
    }
    // ...
    bboxes.clear();
    pathX.clear();
    pathY.clear();
    g.lineStyle(1, Colors.blue.withOpacity(.5));
    for (var i = 0; i < buttons.length; ++i) {
      var btn = buttons[i];
      if (i == 0) {
        pathX.start = btn.x;
        pathY.start = btn.y;
        g.moveTo(btn.x, btn.y);
      } else {
        /// curve here.
        var prev = buttons[i - 1];
        var p1 = prev.nextControl;
        var p2 = btn.prevControl;
        var anchor = btn;
        if (p1 != null && p2 != null) {
          g.cubicCurveTo(p1.x, p1.y, p2.x, p2.y, anchor.x, anchor.y);
          pathX.cubicBezier(anchor.x, p1.x, p2.x, anchor.strength);
          pathY.cubicBezier(anchor.y, p1.y, p2.y, anchor.strength);
          if (useBBox) {
            bboxes.add(
              bezierMinMax(
                prev.x,
                prev.y,
                p1.x,
                p1.y,
                p2.x,
                p2.y,
                btn.x,
                btn.y,
              ),
            );
          }
        }
      }
    }
  }

  void _drawHandlerLines() {
    final g = handlerContainer.graphics;
    g.lineStyle(1, Colors.yellow.withOpacity(.5));
    for (var btn in buttons) {
      if (btn.prevControl != null) {
        g.moveTo(btn.x, btn.y);
        g.lineTo(btn.prevControl!.x, btn.prevControl!.y);
      }
      if (btn.nextControl != null) {
        g.moveTo(btn.x, btn.y);
        g.lineTo(btn.nextControl!.x, btn.nextControl!.y);
      }
    }
  }

  void _drawStrengthLines() {
    final g = handlerContainer.graphics;
    g.lineStyle(1, Colors.green.withOpacity(.5));
    for (var btn in buttons) {
      final control = btn.strengthControl;
      if (control != null) {
        g.moveTo(btn.x, btn.y);
        g.lineTo(control.x, control.y);

        /// draw line steps
        var dy = btn.y - control.y;
        var dir = dy.sign;

        /// each 10 px.
        var count = dy ~/ 10;
        for (var i = 0; i < count.abs(); ++i) {
          var y = btn.y - (i + 1) * 10 * dir;
          g.moveTo(btn.x - 5, y);
          g.lineTo(btn.x + 5, y);
        }
      }
    }
  }

  AnchorButton addAnchor(
    bool first,
    bool last, [
    double px = 0,
    double py = 0,
  ]) {
    var btn = handlerContainer.addChild(AnchorButton(this));
    btn.setPosition(px, py);
    btn.dragBounds = GRect(0, 0, w, h);
    btn.onDrag.add(_handleButtonDrag);
    if (!first) {
      var handler = addControlHandler(btn);
      btn.prevControl = handler;
      handler.x = btn.x - 10;
    }
    if (!last) {
      var handler = addControlHandler(btn);
      btn.nextControl = handler;
      handler.x = btn.x + 10;
    }
    if (config.useStrengthHandler) {
      var handler = addControlHandler(btn);
      handler.color = Colors.green;
      handler.radius = 2;
      handler.x = btn.x;
      handler.y = btn.y - 20;
      btn.strengthControl = handler;
      btn.updateStrengthBounds();
    }
    btn.nextControl?.otherHandler = btn.prevControl;
    btn.prevControl?.otherHandler = btn.nextControl;
    return btn;
  }

  ControlButton addControlHandler(AnchorButton owner) {
    var btn = handlerContainer.addChild(ControlButton(this));
    btn.owner = owner;
    btn.dragBounds = owner.dragBounds.clone();
    btn.onDrag.add(_handleButtonDrag);
    btn.y = owner.y;
    return btn;
  }

  void _handleButtonDrag(BaseButton btn) {
    if (btn is ControlButton) {
      var control = btn.owner;
      var other = btn.otherHandler;
      if (other != null) {
        if (config.isMirrorHandler) {
          _updateControlPosition(btn, control, other, btn.distance(control));
        } else if (config.isMirrorDir) {
          _updateControlPosition(btn, control, other, other.distance(control));
        }
      }
    }
    updateCurve();
  }

  /// MODES.
  bool isModeAddRemove() {
    return false;
  }

  void _updateControlPosition(
    ControlButton btn,
    AnchorButton control,
    ControlButton other,
    double distance,
  ) {
    double a = control.angle(btn);
    other.x = control.x + distance * Math.cos(a);
    other.y = control.y + distance * Math.sin(a);
  }

  void toggleControls() {
    _showHandlers = !_showHandlers;
    for (var btn in buttons) {
      btn.showHandlers(_showHandlers);
    }
    updateCurve();
  }
}
