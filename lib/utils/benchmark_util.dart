typedef DurationCallback = void Function(Duration duration);

int getDurationAverageInMillis(List<Duration> durations) {
  return durations.map((it) => it.inMilliseconds).fold(0, (a, b) => a + b) ~/
      (durations.length > 0.0 ? durations.length : 1);
}

String printDurationsInMillis(List<Duration> duraions) {
  return duraions.map((it) => it.inMilliseconds).join(",");
}
