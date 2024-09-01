import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final int spectrogramHorizontalCount = 440;
  final int spectrogramVerticalCount = 120;
  final int fps = 10;
  final _random = Random();

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

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    _sampleDataTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      buffer.value.add(List<double>.generate(spectrogramHorizontalCount,
          (_) => 0 + _random.nextDouble() * (1.0 - 0)));
    });
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _sampleDataTimer?.cancel();
    super.onClose();
  }
}
