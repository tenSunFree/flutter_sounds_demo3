import 'package:flutter/material.dart';
import 'package:sounds_demo/home/home_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('FlutterSoundsDemo3')),
          body: HomeScreen()));
}
