import 'package:get/get.dart';

enum RfMode {
  AM,
  FM,
  USB,
  LSB,
  CW,
}

class RfService extends GetxService {
  RxInt vfo = 7040100.obs;

  String get vfoKh => "${(vfo / 1000).toStringAsFixed(2)} kHz";
}
