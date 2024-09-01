import 'package:fl_tidal101/utils/RingBuffer.dart';
import 'package:flutter/material.dart';

class SpectrogramWidget extends StatelessWidget {
  final RingBuffer<List<double>> data;
  final int numFrequencies;
  final bool debug;

  const SpectrogramWidget(
      {required this.data,
      required this.numFrequencies,
      this.debug = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpectrogramPainter(data, numFrequencies, onFramePainted: () {
        if (debug) {
          debugPrint("repaint");
        }
      }, debug: debug),
    );
  }
}

class SpectrogramPainter extends CustomPainter {
  final RingBuffer<List<double>> data;
  final int numFrequencies;
  final VoidCallback onFramePainted;
  final bool debug;

  SpectrogramPainter(this.data, this.numFrequencies,
      {required this.onFramePainted, this.debug = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cellWidth = size.width / numFrequencies;
    final cellHeight = size.height / data.capacity;
    if (debug) {
      debugPrint("CANVAS: width: ${size.width} height: ${size.height}");
      debugPrint("CELL: width: $cellWidth height: $cellHeight");
    }

    for (final (index, item) in data.indexed) {
      for (int j = 0; j < numFrequencies; j++) {
        double intensity = item[j];
        paint.color = getColorForIntensity(intensity);

        final rect = Rect.fromLTWH(
          j * cellWidth,
          size.height - (index + 1) * cellHeight, // 시간 축을 아래쪽에서 위쪽으로 그리기
          cellWidth,
          cellHeight,
        );

        canvas.drawRect(rect, paint);
      }
    }

    onFramePainted(); // 프레임이 그려질 때마다 호출하여 FPS 계산에 사용
  }

  Color getColorForIntensity(double intensity) {
    final normalizedIntensity = intensity.clamp(0.0, 1.0);
    return Color.lerp(
        Colors.blue, Colors.red, normalizedIntensity)!; // 강도에 따라 색상 그라데이션 생성
  }

  @override
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    // 데이터가 변경되었을 때만 다시 그리도록 설정
    // return oldDelegate.data != data;
    return true;
  }
}
