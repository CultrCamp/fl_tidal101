import 'dart:async';
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
  final int spectrogramHorizontalCount = 192;
  final int spectrogramVerticalCount = 120;
  final int fps = 10;
  final _random = Random();

  final int chunkSize = 4096;
  final buckets = 480;
  STFT? _stft;
  final totalDuration = 0.0.obs;
  final currentDuration = 0.0.obs;

  STFT get stft {
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
    var audio = _normalizeRmsVolume(wav.toMono(), 0.1).toList();
    totalDuration.value = wav.duration;
    for (double d = 0.0; d <= wav.duration; d += 0.1) {
      currentDuration.value = d;
      var chunked =
          audio.take(wav.samplesPerSecond ~/ 10).toList(growable: false);
      audio = audio.skip(wav.samplesPerSecond ~/ 10).toList();
      stft.stream(chunked, (Float64x2List chunk) {
        final amp = chunk.discardConjugates().magnitudes();

        List<double> temp = List.empty(growable: true);
        for (int bucket = 0; bucket < buckets; ++bucket) {
          int start = (amp.length * bucket) ~/ buckets;
          int end = (amp.length * (bucket + 1)) ~/ buckets;
          temp.add(_rms(Float64List.sublistView(amp, start, end)));
        }
        buffer.value.add(temp);
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

// Returns a copy of the input audio, with the amplitude adjusted so that the
// RMS volume of the result is set to the target.
  Float64List _normalizeRmsVolume(List<double> audio, double target) {
    double factor = target / _rms(audio);
    final output = Float64List.fromList(audio);
    for (int i = 0; i < audio.length; ++i) {
      output[i] *= factor;
    }
    return output;
  }

  double _rms(List<double> audio) {
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
    super.onClose();
  }
}
