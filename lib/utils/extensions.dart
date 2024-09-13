extension StringExtensions on String {}

extension NumberExtensions on num {
  String get formatFrequency {
    // Thresholds for SI units
    const double kilo = 1e3;
    const double mega = 1e6;
    const double giga = 1e9;

    // Determine the appropriate SI unit
    if (this >= giga) {
      return '${(this / giga).toStringAsFixed(2)} GHz';
    } else if (this >= mega) {
      return '${(this / mega).toStringAsFixed(2)} MHz';
    } else if (this >= kilo) {
      return '${(this / kilo).toStringAsFixed(2)} kHz';
    } else {
      return '${this.toStringAsFixed(2)} Hz';
    }
  }
}

extension DoubleExtensions on double {
  int compress(
      {int targetMin = 0,
      int targetMax = 0xFFFFFFFF,
      double inputMin = 0.0,
      double inputMax = 1.0}) {
    var procVar = this > inputMax ? 1.0 : this;
    return (procVar * targetMax).toInt();
  }
}
