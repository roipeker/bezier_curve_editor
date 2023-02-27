import 'package:flutter/material.dart';

import 'main.dart';

class CurveEditorControls extends StatelessWidget {
  const CurveEditorControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Text(
              'Duration',
              style: TextStyle(color: Colors.white24),
            ),
            AnimatedBuilder(
              animation: onTimeChanged,
              builder: (_, __) => Slider(
                  value: onTimeChanged.value,
                  label: onTimeChanged.value.toStringAsFixed(2),
                  divisions: 10,
                  min: 1,
                  max: 10,
                  onChanged: (a) {
                    onTimeChanged.value = a;
                  }),
            ),
          ],
        ),
        // _ShortcutDetails(),
      ],
    );
  }
}

class _ShortcutDetails extends StatelessWidget {
  const _ShortcutDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.white30, fontSize: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getShort('Ctrl+C ', 'Copy data clipboard'),
            getShort('Ctrl+V ', 'Paste data from clipboard'),
            getShort('A ', 'Add/Remove control point'),
            getShort('Num1 ', 'Debug lineTo'),
            getShort('Num2 ', 'Debug handlers'),
          ],
        ),
      ),
    );
  }

  Widget getShort(String title, String value) {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return Row(
      children: [
        Text(
          '$title ',
          style: bold,
        ),
        Text(value),
      ],
    );
  }
}
