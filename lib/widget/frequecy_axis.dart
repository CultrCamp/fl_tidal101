import 'package:fl_tidal101/utils/extensions.dart';
import 'package:flutter/material.dart';

class FrequencyAxis extends StatelessWidget {
  final int numLabels;
  final int maxFrequency;

  const FrequencyAxis(
      {this.numLabels = 20, this.maxFrequency = 1000, super.key});

  @override
  Widget build(BuildContext context) {
    const labelStyle = const TextStyle(fontSize: 12, color: Colors.white);
    final labels = List.generate(numLabels, (index) {
      final frequency = (index / (numLabels - 1)) * maxFrequency;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('|', style: labelStyle),
          Text(frequency.formatFrequency, style: labelStyle)
        ],
      );
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels,
    );
  }
}
