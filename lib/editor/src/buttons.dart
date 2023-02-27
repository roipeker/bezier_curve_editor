part of curve_editor;

abstract class BaseButton extends AbsSprite {
  late double radius;
  late double hitRadius;
  late Color color;
  GRect dragBounds = GRect();
  final onDrag = EventSignal<BaseButton>();
  late CurveEditor editor;

  BaseButton(
    this.editor, [
    this.radius = 2,
    this.hitRadius = 0,
    this.color = Colors.red,
  ]);

  @override
  void dispose() {
    onDrag.removeAll();
    super.dispose();
  }

  @override
  void addedToStage() {
    super.addedToStage();
    onMouseDown.add(_onMouseDown);
  }

  void _onMouseDown(MouseInputData event) {
    if (!inStage) {
      return;
    }
    // if (editor.isModeAddRemove()) {
    //   return;
    // }
    _processMouseDown();
    stage?.onMouseMove.add(_onMouseMove);
    stage?.onMouseUp.addOnce(_onMouseUp);
    startDrag(true, dragBounds);
  }

  /// override it.
  void _processMouseDown() {}

  void _onMouseMove(MouseInputData event) {
    onDrag.dispatch(this);
  }

  void _onMouseUp(MouseInputData event) {
    stage?.onMouseMove.remove(_onMouseMove);
    stopDrag();
  }

  @override
  void draw() {
    graphics
        .clear()
        .beginFill(Colors.white10)
        .drawCircle(0, 0, hitRadius)
        .beginFill(color)
        .drawCircle(0, 0, radius)
        .endFill();
  }

  // utility.
  double distance(GDisplayObject other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  double angle(GDisplayObject other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return Math.atan2(dy, dx);
  }
}

class AnchorButton extends BaseButton {
  ControlButton? prevControl, nextControl;
  ControlButton? strengthControl;

  final _prevPos = GPoint();
  final _nextPos = GPoint();
  final _strengthPos = GPoint();

  /// curve Strength/Weight.
  double get strength {
    if (strengthControl == null) return 1.0;
    var value = (y - strengthControl!.y) / 20;
    return Math.max(0.1, value);
  }

  AnchorButton(CurveEditor editor) : super(editor, 4, 10, Colors.red);

  @override
  void _processMouseDown() {
    if (editor.isModeAddRemove()) {
      return;
    }
    _saveHandlersPositions();
  }

  void updateStrengthBounds() {
    if (strengthControl != null) {
      strengthControl!.dragBounds.width = 0;
      strengthControl!.dragBounds.x = x;
      strengthControl!.dragBounds.height = y;
    }
    prevControl?.dragBounds.copyFrom(dragBounds);
    nextControl?.dragBounds.copyFrom(dragBounds);
  }

  @override
  void _onMouseMove(MouseInputData event) {
    super._onMouseMove(event);
    updateStrengthBounds();
    _restoreHandlerPosition(prevControl, _prevPos);
    _restoreHandlerPosition(nextControl, _nextPos);
    _restoreHandlerPosition(strengthControl, _strengthPos);
  }

  void _saveHandlersPositions() {
    _saveHandlerPosition(prevControl, _prevPos);
    _saveHandlerPosition(nextControl, _nextPos);
    _saveHandlerPosition(strengthControl, _strengthPos);
  }

  void _saveHandlerPosition(BaseButton? btn, GPoint point) {
    if (btn == null) return;
    point.x = btn.x - x;
    point.y = btn.y - y;
  }

  void _restoreHandlerPosition(BaseButton? btn, GPoint pos) {
    if (btn == null) return;
    btn.x = x + pos.x;
    btn.y = y + pos.y;
  }

  void removeAll() {
    strengthControl?.removeFromParent(true);
    prevControl?.removeFromParent(true);
    nextControl?.removeFromParent(true);
    removeFromParent(true);
  }

  void showHandlers(bool flag) {
    prevControl?.visible = flag;
    nextControl?.visible = flag;
    strengthControl?.visible = flag;
  }

  @override
  void dispose() {
    prevControl = null;
    nextControl = null;
    strengthControl = null;
    super.dispose();
  }
}

class ControlButton extends BaseButton {
  late AnchorButton owner;

  /// opposite control button.
  ControlButton? otherHandler;

  ControlButton(CurveEditor editor) : super(editor, 2, 8, Colors.yellow);

  @override
  void dispose() {
    otherHandler = null;
    super.dispose();
  }
}
