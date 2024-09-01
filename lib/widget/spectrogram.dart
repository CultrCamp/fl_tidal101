import 'dart:core';

import 'package:fl_tidal101/utils/RingBuffer.dart';
import 'package:flutter/material.dart';

class Spectrogram extends StatelessWidget {
  final Map<double, Color> intensityColorMap;
  final RingBuffer<List<double>> data;
  final int horizontalCount;
  final int verticalCount;
  final bool debug;

  const Spectrogram(
      {required this.data,
      required this.horizontalCount,
      this.verticalCount = 120,
      this.debug = false,
      required this.intensityColorMap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpectrogramPainter(data, horizontalCount, verticalCount,
          onFramePainted: () {
        if (debug) {
          debugPrint("repaint");
        }
      }, intensityColorMap: intensityColorMap, debug: debug),
    );
  }
}

class SpectrogramPainter extends CustomPainter {
  final RingBuffer<List<double>> data;
  final int horizontalCount;
  final int verticalCount;
  final VoidCallback onFramePainted;
  final bool debug;

  // 강도에 따른 색상 매핑
  final Map<double, Color> intensityColorMap;

  SpectrogramPainter(
    this.data,
    this.horizontalCount,
    this.verticalCount, {
    required this.onFramePainted,
    required this.intensityColorMap,
    this.debug = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.black; // 배경 색상 설정

    // 전체 화면 크기의 사각형을 만듭니다.
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paintBg);

    final paint = Paint();
    final cellWidth = size.width / horizontalCount;
    final cellHeight = size.height / verticalCount;
    if (debug) {
      debugPrint("CANVAS: width: ${size.width} height: ${size.height}");
      debugPrint("CELL: width: $cellWidth height: $cellHeight");
    }

    for (final (int index, List<double> item) in data.indexed) {
      for (int j = 0; j < item.length; j++) {
        double intensity = item[j];
        paint.color = getColorForIntensity(intensity); // 색상 결정

        final rect = Rect.fromLTWH(
          j * cellWidth,
          (index + 1) * cellHeight, // 시간 축을 아래쪽에서 위쪽으로 그리기
          cellWidth,
          cellHeight,
        );

        canvas.drawRect(rect, paint);
      }
    }

    onFramePainted(); // 프레임이 그려질 때마다 호출하여 FPS 계산에 사용
  }

  // 강도에 따라 색상을 반환하는 함수 (중간값 그라데이션 적용)
  Color getColorForIntensity(double intensity) {
    final sortedKeys = intensityColorMap.keys.toList()..sort();

    // 중간값을 찾기 위한 색상 정의
    for (int i = 0; i < sortedKeys.length - 1; i++) {
      double lower = sortedKeys[i];
      double upper = sortedKeys[i + 1];

      if (intensity >= lower && intensity <= upper) {
        double t = (intensity - lower) / (upper - lower);
        return Color.lerp(
            intensityColorMap[lower], intensityColorMap[upper], t)!;
      }
    }

    // 강도가 맵의 범위를 벗어난 경우에 대한 처리
    if (intensity <= sortedKeys.first) {
      return intensityColorMap[sortedKeys.first]!;
    } else {
      return intensityColorMap[sortedKeys.last]!;
    }
  }

  @override
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    // 데이터가 변경되었을 때만 다시 그리도록 설정
    return oldDelegate.data != data;
  }
}
