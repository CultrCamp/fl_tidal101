import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wav/wav.dart';

import '../../utils/RingBuffer.dart';

class IndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => IndexController());
  }
}

class IndexController extends GetxController {
  Timer? _sampleDataTimer;
  RxInt currentFps = 0.obs;
  int _lastTick = 0;
  RxInt intensityColorMapIndex = 0.obs;
  final Rx<RingBuffer<List<double>>> buffer = Rx(RingBuffer(120));
  final int fps = 10;
  final int bufferSizeInSec = 15;
  final _random = Random();

  static const int chunkSize = 2048;
  static int buckets = 480;
  static const int targetResolutionInHz = 250;
  static STFT? _stft;
  final totalDuration = 0.0.obs;
  final currentDuration = 0.0.obs;
  final RxInt bitPerSample = 0.obs;
  final RxInt samplesPerSecond = 0.obs;

  DateTime measureStart = DateTime.now();
  final List<Duration> durations = List.empty(growable: true);

  Isolate? _fftIsolate;
  ReceivePort? _receivePort;

  static STFT get stft {
    _stft ??= STFT(chunkSize, Window.hamming(chunkSize));
    return _stft!;
  }

  final List<Map<double, Color>> intensityColorMaps = [
    {
      0.0: Colors.black,
      0.25: Colors.indigo,
      0.5: Colors.yellow,
      0.75: Colors.deepOrange,
      1.0: Colors.red,
    }
  ];

  int get updateMillis => 1000 ~/ fps;

  int _millisToFps(int millis) {
    if (millis <= 0) {
      return 0;
    }
    return 1000 ~/ millis;
  }

  void updateFps(Duration elapsed) {
    int millis = elapsed.inMilliseconds - _lastTick;
    _lastTick = elapsed.inMilliseconds;
    currentFps.value = _millisToFps(millis);
    // debugPrint("update frame(e: ${millis}ms, $currentFps)");
  }

  void doSTFT(String filePath) async {
    final wav = await Wav.readFile(filePath);
    debugPrint("wav file loaded");
    var audio = _normalizeRmsVolume(wav.toMono(), 0.05).toList();
    totalDuration.value = wav.duration;
    bitPerSample.value = wav.format.bitsPerSample;
    final _samplesPerSecond = wav.samplesPerSecond;
    samplesPerSecond.value = _samplesPerSecond;
    buckets = _samplesPerSecond ~/ targetResolutionInHz;
    const chunkLengthInSec = 0.05;
    buffer.value.capacity = bufferSizeInSec ~/ chunkLengthInSec;
    final chunkSize = (_samplesPerSecond * chunkLengthInSec).toInt();

    if (_fftIsolate != null) {
      debugPrint("isolate exists. kill it");
      _cleanupIsolate();
    }
    _receivePort = ReceivePort();
    _fftIsolate = await Isolate.spawn(_fftIsolateEntry, [
      _receivePort!.sendPort,
      audio,
      chunkSize,
      buckets,
      chunkLengthInSec,
      totalDuration.value
    ]);
    debugPrint("fft started");

    _receivePort!.listen((message) {
      if (message is List<double>) {
        buffer.value.add(message);
      } else if (message is double) {
        currentDuration.value = message;
      } else if (message == "done") {
        _cleanupIsolate();
      }
    });
  }

  void _cleanupIsolate() {
    _fftIsolate?.kill(priority: Isolate.immediate);
    _fftIsolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  static void _fftIsolateEntry(List<dynamic> args) async {
    SendPort sendPort = args[0];
    List<double> audio = args[1];
    int chunkSize = args[2];
    int buckets = args[3];
    double chunkLengthInSec = args[4];
    double totalDuration = args[5];
    double currentDuration = 0.0;
    for (;
        currentDuration <= totalDuration;
        currentDuration += chunkLengthInSec) {
      var chunked = audio.take(chunkSize).toList(growable: false);
      audio = audio.skip(chunkSize ~/ 2).toList(); //  Make overlap
      stft.stream(chunked, (Float64x2List chunk) {
        final amp = chunk.discardConjugates().magnitudes();

        List<double> temp = List.empty(growable: true);
        for (int bucket = 0; bucket < buckets; ++bucket) {
          int start = (amp.length * bucket) ~/ buckets;
          int end = (amp.length * (bucket + 1)) ~/ buckets;
          temp.add(_rms(Float64List.sublistView(amp, start, end)));
        }
        sendPort.send(temp);
      }, chunkSize ~/ 2);
      await Future.delayed(
          Duration(milliseconds: (chunkLengthInSec * 1000).toInt()));
      currentDuration += chunkLengthInSec;
      sendPort.send(currentDuration);
    }
    sendPort.send("done");
  }

// Returns a copy of the input audio, with the amplitude adjusted so that the
// RMS volume of the result is set to the target.
  static Float64List _normalizeRmsVolume(List<double> audio, double target) {
    double factor = target / _rms(audio);
    final output = Float64List.fromList(audio);
    for (int i = 0; i < audio.length; ++i) {
      output[i] *= factor;
    }
    return output;
  }

  static double _rms(List<double> audio) {
    if (audio.isEmpty) {
      return 0;
    }
    double squareSum = 0;
    for (final x in audio) {
      squareSum += x * x;
    }
    return sqrt(squareSum / audio.length);
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    // _sampleDataTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
    //   buffer.value.add(List<double>.generate(spectrogramHorizontalCount,
    //       (_) => 0 + _random.nextDouble() * (1.0 - 0)));
    // });
  }

  @override
  void onClose() {
    // TODO: implement onClose
    // _sampleDataTimer?.cancel();
    _cleanupIsolate();
    super.onClose();
  }
}
