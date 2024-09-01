import 'dart:async';
import 'dart:math';

import 'package:fl_tidal101/utils/RingBuffer.dart';
import 'package:fl_tidal101/widgets/spectrogram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Timer? _sampleDataTimer;
  int _fps = 0;
  final RingBuffer<List<double>> _buffer = RingBuffer(60);
  final int _numFreq = 441;
  final int fps = 10;
  final _random = Random();

  int get updateMillis => 1000 ~/ fps;

  void _incrementCounter() {
    setState(() {});
  }

  int millisToFps(int millis) {
    if (millis <= 0) {
      return 0;
    }
    return 1000 ~/ millis;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _ticker = Ticker((elapsed) {
      int millis = elapsed.inMicroseconds;
      int fps = millisToFps(millis);
      debugPrint("update frame(e: ${millis}ms, $fps)");
      setState(() {
        _fps = fps;
      });
    })
      ..start();
    _sampleDataTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        debugPrint("update data");
        _buffer.add(List<double>.generate(
            _numFreq, (_) => 0 + _random.nextDouble() * (1.0 - 0)));
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _ticker?.dispose();
    _sampleDataTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Stack(
        children: [
          Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: SpectrogramWidget(
                  data: _buffer, numFrequencies: _numFreq, debug: true)),
          Text("${_fps}fps")
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
