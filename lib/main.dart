import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';

import 'editor/editor.dart';
import 'widgets.dart';

final onTimeChanged = ValueNotifier<double>(2);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: SceneBuilderWidget(
                builder: () => SceneController(
                  front: MainEditor(),
                  config: SceneConfig.tools,
                ),
                autoSize: true,
                painterIsComplex: true,
              ),
            ),
          ),
          CurveEditorControls(),
        ],
      ),
    );
  }
}
