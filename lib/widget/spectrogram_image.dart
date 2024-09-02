import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:fl_tidal101/utils/RingBuffer.dart';
import 'package:fl_tidal101/utils/benchmark_util.dart';
import 'package:flutter/material.dart';

class SpectrogramImage extends StatelessWidget {
  final Map<double, Color> intensityColorMap;
  final RingBuffer<List<double>> data;
  final bool debug;
  final DurationCallback? durationCallback;

  const SpectrogramImage({
    required this.data,
    this.debug = false,
    required this.intensityColorMap,
    this.durationCallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpectrogramImagePainter(
        data,
        onFramePainted: (duration) {
          if (debug) {
            debugPrint("repaint");
          }
          if (durationCallback != null) {
            durationCallback!(duration);
          }
        },
        intensityColorMap: intensityColorMap,
        debug: debug,
      ),
    );
  }
}

class SpectrogramImagePainter extends CustomPainter {
  final RingBuffer<List<double>> data;
  final DurationCallback onFramePainted;
  final bool debug;

  // 색상 매핑을 위한 캐시
  final List<double> sortedKeys;
  final List<Color> colors;
  final Map<double, Color> intensityColorMap;

  Uint8List buffer;
  bool _needsRedraw = true;
  ui.Image? _cachedImage; // 캐시된 이미지

  SpectrogramImagePainter(
    this.data, {
    required this.onFramePainted,
    required this.intensityColorMap,
    this.debug = false,
  })  : sortedKeys = intensityColorMap.keys.toList()..sort(),
        colors = intensityColorMap.values.toList(),
        buffer = Uint8List(0);

  @override
  void paint(Canvas canvas, Size size) async {
    final start = DateTime.now();

    // if (_needsRedraw) {
    _updateBuffer(size);
    _generateImageFromBuffer(size).then((image) {
      _cachedImage = image;
      if (_cachedImage != null) {
        final srcRect = Rect.fromLTWH(0, 0, _cachedImage!.width.toDouble(),
            _cachedImage!.height.toDouble());
        final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawImageRect(_cachedImage!, srcRect, dstRect, Paint());
        // canvas.drawImage(_cachedImage!, Offset.zero, Paint());
      }
    });
    // } else
    if (_cachedImage != null) {
      final srcRect = Rect.fromLTWH(0, 0, _cachedImage!.width.toDouble(),
          _cachedImage!.height.toDouble());
      final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(_cachedImage!, srcRect, dstRect, Paint());
      // canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
    final end = DateTime.now();
    onFramePainted(end.difference(start)); // 프레임이 그려질 때마다 호출하여 FPS 계산에 사용
  }

  void _updateBuffer(Size size) {
    final boxHeight = size.height / data.capacity;
    final boxWidth = size.width / data.first.length;
    buffer = Uint8List(data.capacity * data.first.length * 4);

    int bufferIndex = 0;
    for (final (int i, List<double> item) in data.indexed) {
      for (final (int j, double intensity) in item.indexed) {
        final color = getColorForIntensity(intensity);
        buffer[bufferIndex++] = color.red;
        buffer[bufferIndex++] = color.green;
        buffer[bufferIndex++] = color.blue;
        buffer[bufferIndex++] = color.alpha;
      }
    }
  }

  Future<ui.Image?> _generateImageFromBuffer(Size size) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      buffer,
      data.first.length,
      data.capacity,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    return await completer.future;
  }

  // 강도에 따라 색상을 반환하는 함수 (중간값 그라데이션 적용)
  Color getColorForIntensity(double intensity) {
    // 이진 탐색을 통해 중간값을 빠르게 찾음
    int low = 0;
    int high = sortedKeys.length - 1;

    if (intensity <= sortedKeys[low]) {
      return colors[low];
    } else if (intensity >= sortedKeys[high]) {
      return colors[high];
    }

    while (low <= high) {
      int mid = (low + high) >> 1;
      if (intensity == sortedKeys[mid]) {
        return colors[mid];
      } else if (intensity < sortedKeys[mid]) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // 두 인접한 색상 사이의 비율 계산
    double lower = sortedKeys[high];
    double upper = sortedKeys[low];
    double t = (intensity - lower) / (upper - lower);
    return Color.lerp(colors[high], colors[low], t)!;
  }

  @override
  bool shouldRepaint(covariant SpectrogramImagePainter oldDelegate) {
    // 데이터를 부분적으로 비교하거나, 변경된 경우에만 true 반환
    if (oldDelegate.data != data || oldDelegate.debug != debug) {
      _needsRedraw = true;
    }
    return true;
  }
}
