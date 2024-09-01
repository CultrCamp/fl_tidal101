import 'dart:ui';

import 'package:fl_tidal101/utils/RingBuffer.dart';
import 'package:flutter/material.dart';

class Spectrogram extends StatelessWidget {
  final Map<double, Color> intensityColorMap;
  final RingBuffer<List<double>> data;
  final bool debug;

  const Spectrogram(
      {required this.data,
      this.debug = false,
      required this.intensityColorMap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpectrogramPainter(data, onFramePainted: () {
        if (debug) {
          debugPrint("repaint");
        }
      }, intensityColorMap: intensityColorMap, debug: debug),
    );
  }
}

class SpectrogramPainter extends CustomPainter {
  final RingBuffer<List<double>> data;
  final VoidCallback onFramePainted;
  final bool debug;

  // 색상 매핑을 위한 캐시
  final List<double> sortedKeys;
  final List<Color> colors;
  final Map<double, Color> intensityColorMap;

  SpectrogramPainter(
    this.data, {
    required this.onFramePainted,
    required this.intensityColorMap,
    this.debug = false,
  })  : sortedKeys = intensityColorMap.keys.toList()..sort(),
        colors = intensityColorMap.values.toList();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final boxHeight = size.height / data.capacity;

    for (final (int i, List<double> item) in data.indexed) {
      final boxWidth = size.width / item.length;
      for (final (int j, double intensity) in item.indexed) {
        paint.color = getColorForIntensity(intensity); // 색상 결정

        // 각 상자의 좌표를 계산 (아래쪽이 최신 데이터가 되도록)
        final bottomLeft = Offset(j * boxWidth, i * boxHeight);
        final topLeft = Offset(j * boxWidth, i * boxHeight + boxHeight);
        final topRight = Offset(j * boxWidth + boxWidth, i * boxHeight + boxHeight);
        final bottomRight = Offset(j * boxWidth + boxWidth, i * boxHeight);

        // 사각형 그리기
        final vertices = Vertices(
          VertexMode.triangleFan,
          [bottomLeft, bottomRight, topRight, topLeft],
          colors: [paint.color, paint.color, paint.color, paint.color],
        );

        canvas.drawVertices(vertices, BlendMode.src, paint);
      }
    }

    onFramePainted(); // 프레임이 그려질 때마다 호출하여 FPS 계산에 사용
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
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    // 데이터를 부분적으로 비교하거나, 변경된 경우에만 true 반환
    return oldDelegate.data != data || oldDelegate.debug != debug;
  }
}
