part of curve_editor;

class MainEditor extends Sprite {
  MainEditor();

  late CurveEditor editor;
  late GShape ball;
  @override
  void addedToStage() {
    GKeyboard.init(stage!);
    editor = addChild(CurveEditor(sw, 100));
    ball = addBall();
    stage!.onResized.add(_onStageResized);
  }

  @override
  void update(double delta) {
    super.update(delta);
    var timeScale = onTimeChanged.value;
    var t = getTimer().wrapLerp(1000 * timeScale);
    // t = t.reverse(linear).sineOut();
    // t = t.sineOut();
    var px = editor.pathX.transform(t);
    var py = editor.pathY.transform(t);
    ball.x = px;
    ball.y = py + editor.y + editor.h;
  }

  void _onStageResized() {
    editor.setSize(sw, 200);
  }

  GShape addBall() {
    var shape = addChild(GShape());
    shape.graphics
        .beginFill(Colors.purple.withOpacity(.5))
        .drawCircle(0, 0, 20)
        .endFill();
    return shape;
  }
}
