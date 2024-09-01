import 'dart:async';

import 'package:flutter/material.dart';

class SpectrogramWidget extends StatefulWidget {
  final List<List<double>> data;
  final int numFrequencies;
  final int numTimeSteps;
  final bool debug;

  SpectrogramWidget({
    required this.data,
    required this.numFrequencies,
    required this.numTimeSteps,
    this.debug = false,
  });

  @override
  State createState() => _SpectrogramWidgetState();
}

class _SpectrogramWidgetState extends State<SpectrogramWidget> {
  late Timer _fpsTimer;
  int _frameCount = 0;
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.debug) {
      _startFPSTimer();
    }
  }

  void _startFPSTimer() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _fps = _frameCount / 10.0; // 10초 동안의 평균 FPS 계산
        debugPrint('Average FPS: $_fps');
        _frameCount = 0; // 프레임 카운트 초기화
      });
    });
  }

  @override
  void dispose() {
    if (widget.debug) {
      _fpsTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpectrogramPainter(
          widget.data, widget.numFrequencies, widget.numTimeSteps,
          onFramePainted: () {
        if (widget.debug) {
          _frameCount++; // 프레임 카운트 증가
        }
      }),
    );
  }
}

class SpectrogramPainter extends CustomPainter {
  final List<List<double>> data;
  final int numFrequencies;
  final int numTimeSteps;
  final VoidCallback onFramePainted;

  SpectrogramPainter(this.data, this.numFrequencies, this.numTimeSteps,
      {required this.onFramePainted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cellWidth = size.width / numFrequencies;
    final cellHeight = size.height / numTimeSteps;

    for (int i = 0; i < numFrequencies; i++) {
      for (int j = 0; j < numTimeSteps; j++) {
        double intensity = data[i][j];
        paint.color = getColorForIntensity(intensity);

        final rect = Rect.fromLTWH(
          i * cellWidth,
          size.height - (j + 1) * cellHeight, // 시간 축을 아래쪽에서 위쪽으로 그리기
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
    return oldDelegate.data != data;
  }
}
